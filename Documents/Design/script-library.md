# Script Library Convention

## Problem Context

The Pester test suite for `.github/scripts/` originally spawned a child `pwsh` process for every test
case. Across 218 deterministic tests covering 6 production scripts, this produced ~134 child-process
spawns and a ~216s test run — long enough to hit VS Code Copilot timeout limits and impede the
edit-test loop.

**Scripts affected** (spawn count before refactor):

| Script | Spawns |
|---|---|
| `aggregate-review-scores.ps1` | ~50+ |
| `write-calibration-entry.ps1` | 21 |
| `measure-guidance-complexity.ps1` | ~20 |
| `normalize-whitespace.ps1` | 15 |
| `session-cleanup-detector.ps1` | 9 |
| `backfill-calibration.ps1` | 7 |

After refactoring, the deterministic tests run in ~17s — a 92% reduction. The 49 `requires-gh`
integration tests that call the live GitHub API remain, with timing subject to network conditions.

## Decision

Extract each script's logic into a `lib/{name}-core.ps1` library file that exports a single
`Invoke-*` function. Keep the original script as a thin CLI wrapper that dot-sources the library and
calls the function.

This preserves the public CLI contract of every script while allowing Pester tests to dot-source the
library and invoke the function in-process — no child `pwsh` spawning required.

## Library File Conventions

### File and function naming

- Library path: `.github/scripts/lib/{script-name}-core.ps1`
- Exported function: `Invoke-{PascalCase}` (one public function per library)
- Example: `aggregate-review-scores.ps1` → `lib/aggregate-review-scores-core.ps1` →
  `Invoke-AggregateReviewScores`

### Function signature

```powershell
function Invoke-ExampleScript {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [string]$Param1,
        [string]$GhCliPath = 'gh'   # only for scripts with a gh dependency
    )

    Set-StrictMode -Version Latest
    $ErrorActionPreference = 'Stop'
    # ... logic ...
}
```

- Parameters mirror the CLI wrapper exactly.
- `Set-StrictMode` and `$ErrorActionPreference` are set inside the function body.
- No `exit` calls — all exit paths return a result hashtable instead.

### Return value

Every library function returns:

```powershell
@{
    ExitCode = 0   # or 1
    Output   = '...'
    Error    = '...'
}
```

### Sibling path resolution

Use `$PSCommandPath` (not `$PSScriptRoot`) to locate sibling files. `$PSCommandPath` resolves to the
library file's own path when dot-sourced; `$PSScriptRoot` would resolve to the caller's directory.

```powershell
$script:_ExampleLibDir = Split-Path -Parent $PSCommandPath
. "$script:_ExampleLibDir/pipeline-metrics-helpers.ps1"
```

The `$script:` scope prefix avoids variable collision when multiple libraries are dot-sourced in the
same Pester session scope.

### Private helper prefix

Private functions inside a library use a short uppercase prefix to prevent name collisions when tests
dot-source multiple libraries into the same runspace:

| Library | Prefix | Example |
|---|---|---|
| `normalize-whitespace-core.ps1` | `NW-` | `NW-Test-AllowlistedPath` |
| `write-calibration-entry-core.ps1` | `WCE-` | `WCE-Test-HasProperty` |
| `session-cleanup-detector-core.ps1` | `SCD-` | `SCD-Get-DefaultBranch` |

## CLI Wrapper Conventions

Each wrapper:

1. Dot-sources its library via `$PSScriptRoot`:

   ```powershell
   . "$PSScriptRoot/lib/{name}-core.ps1"
   ```

2. Calls the function, forwarding all parameters with splatting:

   ```powershell
   $result = Invoke-ExampleScript @PSBoundParameters
   ```

3. Relays output and errors, then exits with the function's exit code:

   ```powershell
   if ($result.Output) { Write-Output $result.Output }
   if ($result.Error)  { Write-Error $result.Error -ErrorAction Continue }
   exit $result.ExitCode
   ```

Wrappers contain no logic — they are pure pass-through. Logic lives only in the library.

## Testing Pattern

Test files dot-source the library directly and invoke the function in-process:

```powershell
BeforeAll {
    $script:LibFile = Join-Path $PSScriptRoot '../lib/backfill-calibration-core.ps1'
    . $script:LibFile

    $script:InvokeFn = {
        param([hashtable]$Params)
        Invoke-BackfillCalibration @Params
    }
}

It 'exits 0 when gh returns empty list' {
    $result = & $script:InvokeFn @{ Repo = 'owner/repo'; GhCliPath = $mockGhScript }
    $result.ExitCode | Should -Be 0
}
```

- No `& pwsh -File` spawning in `It` blocks for these tests.
- External binary dependencies (e.g., `gh`) are replaced via `-GhCliPath $mockGhScript`.
- The mock script is a `.ps1` file written to a temp directory in `BeforeAll` that returns fixture
  JSON.
- Shared helpers in `BeforeAll` use the `$script:InvokeXxx` naming pattern.

## Mock Injection Pattern (`-GhCliPath`)

Scripts with a `gh` CLI dependency accept `-GhCliPath` (default: `'gh'`). Tests pass a path to a
mock script that returns controlled fixture data:

```powershell
# In BeforeAll:
$script:MockGh = Join-Path $TestDrive 'gh.ps1'
Set-Content $script:MockGh '@("[{`"number`":42,`"mergedAt`":`"2025-01-01T00:00:00Z`",`"body`":`"`"}]")'

# In a test:
$result = Invoke-BackfillCalibration -Repo 'owner/repo' -GhCliPath $script:MockGh
```

Scripts without a `gh` dependency do not receive this parameter.

## Regression Prevention

`.github/scripts/Tests/script-safety-contract.Tests.ps1` contains an AST-inspection contract test
that scans all `.Tests.ps1` files for `& pwsh` followed by `-File` inside `It` blocks. It fails if
any new test introduces a process-spawn pattern outside the allowlist.

Current allowlist entry: `branch-authority-gate.Tests.ps1` — this test file uses `.cmd` wrappers
for git mock infrastructure and legitimately requires child-process spawning.

## Trade-offs

- **Name collision risk**: Private helpers must use a prefix. Without prefixes, dot-sourcing two
  libraries with a shared helper name (e.g., `Test-HasProperty`) into the same scope silently
  shadows one with the other.
- **Wrapper stays minimal**: No logic may live in both the wrapper and the library. Duplication
  creates drift.
- **Path coupling**: If a library file is renamed or moved, both the wrapper (`$PSScriptRoot/lib/`)
  and the test (`$PSScriptRoot/../lib/`) must be updated.
- **Residual spawns**: `session-cleanup-detector` tests that exercise git mock `.cmd` wrappers still
  spawn child processes. This is a known limitation deferred to a follow-up.

## Documented In

- `.github/copilot-instructions.md` — Script Library Convention section with in-process usage
  example and `-GhCliPath` mock example
- `.github/architecture-rules.md` — `lib/` subdirectory entry in the directory table
- `.github/scripts/Tests/script-safety-contract.Tests.ps1` — AST contract test enforcing the
  no-spawn requirement
