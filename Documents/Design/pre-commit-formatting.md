# Pre-Commit Formatting

## Purpose

Issue #219 closes a repo-tooling gap around PowerShell formatting. Agent-edited `.ps1` files bypass VS Code save-time formatting because tool-driven edits do not trigger an editor save, which led to follow-up style commits after otherwise-correct changes. The implemented design adds commit-time PowerShell normalization without changing the repo's existing Markdown protection model.

## Implemented Surface

| File | Role |
| --- | --- |
| `.githooks/pre-commit` | Shell hook with separate Markdown and PowerShell formatting lanes |
| `.vscode/settings.json` | Workspace-level PowerShell save-time formatting alignment |
| `CONTRIBUTING.md` | Contributor setup guidance and non-blocking formatter behavior |
| `README.md` | Intentionally unchanged so contributor tooling guidance stays in `CONTRIBUTING.md` |

## Design Decisions

### D1 - Keep the shell hook and add a second lane

The repo continues to use `.githooks/pre-commit` as a POSIX shell hook. The existing Markdown lane stays in place, and a second PowerShell lane runs independently against staged `.ps1` files collected from the same cached diff snapshot. Mixed `.md` and `.ps1` commits therefore keep today's Markdown behavior while adding PowerShell normalization in the same commit flow.

### D2 - Format PowerShell on a best-effort basis

The hook resolves PowerShell formatting capability through `pwsh` and `Invoke-Formatter`. If `pwsh` is missing, `PSScriptAnalyzer` cannot be imported, or formatting fails for a specific file, the hook prints a warning and continues. The script still exits successfully, so formatter availability is a quality improvement rather than a commit gate.

### D3 - Preserve encoding and BOM behavior on rewrite

Each staged `.ps1` file is read through `StreamReader`, formatted with `Invoke-Formatter -ScriptDefinition`, and only rewritten when content changes. The rewrite path inspects the original bytes for a UTF-8 BOM, carries forward the detected encoding, and explicitly preserves UTF-8 without BOM when the source file did not start with one. This avoids introducing encoding-only churn while still normalizing formatting.

### D4 - Keep editor and hook expectations aligned

`.vscode/settings.json` now enables `[powershell]` `editor.formatOnSave: true`. This does not replace the hook; it narrows the gap between manual VS Code edits and commit-time behavior so contributors see the same formatting rules earlier.

### D5 - Keep contributor guidance in CONTRIBUTING.md

`CONTRIBUTING.md` is the contributor-facing source for hook setup and formatter prerequisites, so the PowerShell guidance lives there. It documents `pwsh` plus `PSScriptAnalyzer`, explains that staged `.ps1` files are formatted with `Invoke-Formatter`, and makes the non-blocking warning path explicit. `README.md` remains high-level and does not duplicate this setup detail.

## Hook Behavior

1. Collect staged files once with `git diff --cached --name-only --diff-filter=ACM`.
2. Run the Markdown lane for staged `.md` files.
3. Discover staged `.ps1` files from the same staged-file snapshot.
4. Resolve formatter availability once per commit by checking `pwsh`, then `Invoke-Formatter` or an import of `PSScriptAnalyzer`.
5. For each staged `.ps1` file, hash before, format through a literal-path-safe environment variable plus `Resolve-Path -LiteralPath`, hash after, and re-stage only if the file changed.
6. If formatting fails for one file, warn, leave that file unchanged, and continue to the next file.
7. Exit `0` so commits are never blocked by PowerShell tooling availability.

## Scope Boundaries

### In Scope

- Commit-time formatting for staged `.ps1` files in `.githooks/pre-commit`
- Workspace-level PowerShell save-time formatting in `.vscode/settings.json`
- Contributor guidance for prerequisites and hook behavior in `CONTRIBUTING.md`

### Explicit Non-Goals

- Rewriting the hook in PowerShell
- Making `pwsh` or `PSScriptAnalyzer` a hard prerequisite
- Adding CI enforcement or repo-wide formatter policy changes
- Moving contributor setup guidance into `README.md`
- Solving index-only formatting for partially staged files

The last non-goal is deliberate. The repo keeps the existing working-tree/restage model: if formatting changes a staged file, the hook re-stages the full file with `git add`. Partially staged `.ps1` files therefore carry the same caveat as partially staged Markdown files in the current hook design.

## Customer Experience Result

Commit-time paths were exercised directly during issue #219 validation:

- PowerShell-only staged formatting
- Missing-tooling warning behavior
- Mixed Markdown and PowerShell commits

Editor-save parity is implemented and partially evidenced, but not fully exercised in-session:

- The workspace now enables `[powershell]` `editor.formatOnSave: true`.
- Contributor guidance points to the same PowerShell formatter dependency used by the hook.
- An actual VS Code save event was not exercised in-session, so editor parity is documented as configured and aligned in intent rather than fully demonstrated.

## Source Of Truth

This document records the repo state shipped for issue #219. The implementation source of truth is the current content of `.githooks/pre-commit`, `.vscode/settings.json`, and `CONTRIBUTING.md`.
