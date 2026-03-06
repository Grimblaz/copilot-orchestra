# Safe Operations Instructions

## Purpose

Establish safe, consistent rules for file operations and issue creation across all agents in this workflow. These rules prevent silent file corruption and ensure GitHub issues are always properly labeled.

---

## Section 1: File Operation Rules (CRITICAL)

These rules apply whenever any agent uses terminal commands or file tools to read, write, or move files. **PowerShell write commands silently corrupt files** through incorrect encoding, unwanted BOM markers, or inconsistent line endings. Always use the designated tool for each operation.

### Correct Tools by Operation

| Operation             | Correct Tool                                              |
| --------------------- | --------------------------------------------------------- |
| Create a new file     | `create_file`                                             |
| Edit an existing file | `replace_string_in_file` / `multi_replace_string_in_file` |
| Read a file           | `read_file`                                               |
| Delete a file         | `Remove-Item` (terminal)                                  |
| Archive/move a file   | `Move-Item` (terminal)                                    |

### Read-Only & Computable Operations

For operations that only inspect state or compute values, **always prefer dedicated VS Code tools over terminal commands**. Terminal commands trigger a "Run command?" confirmation dialog and return unstructured text — dedicated tools provide structured, typed outputs without interruption.

| Operation                      | Preferred Method            | Do NOT use terminal for                                                             |
| ------------------------------ | --------------------------- | ----------------------------------------------------------------------------------- |
| Inspect changed files / diffs  | `get_changed_files`         | `git diff` (working-tree; cross-branch diff is permitted in terminal), `git status` |
| Read file content              | `read_file`                 | `Get-Content`, `cat`                                                                |
| Search for text in files       | `grep_search`               | `Select-String`, `grep`, `git grep`                                                 |
| List directory contents        | `list_dir` or `file_search` | `Get-ChildItem`, `ls`                                                               |
| Check file/directory existence | `file_search` (glob-based; use exact-path pattern and check for non-empty result) | `Test-Path`                                                                         |
| Arithmetic / coordinate math   | Agent reasoning directly    | `node -e`, `python -c`, `pwsh -c`                                                   |
| Semantic / concept search      | `semantic_search`           | —                                                                                   |

> **Exception**: The "Do NOT use" restrictions above apply to ad-hoc discovery. Project validation commands explicitly permitted in the Rule below (e.g., quick-validate checks in `.github/copilot-instructions.md`) may use `Get-ChildItem`, `Select-String`, and similar terminal commands.

**Rule**: By default, use dedicated VS Code tools for all inspection and read operations. Reserve `run_in_terminal` for: build commands, test runners, file move/delete operations, `gh` CLI calls, git workflow operations (commit, push, checkout, branch), and project validation commands (e.g., quick-validate checks in `.github/copilot-instructions.md`).

---

### FORBIDDEN PowerShell Write Commands

Never use any of the following to write or modify file content:

- `Set-Content`
- `Out-File`
- `Add-Content`
- `New-Item` with `-Value`
- `echo something > file.txt` or `echo something >> file.txt`
- `.NET static IO methods: [System.IO.File]::WriteAllText(), ::AppendAllText(), ::WriteAllLines(), ::WriteAllBytes() — same silent encoding risks`

These PowerShell commands silently corrupt files through encoding issues (e.g., UTF-16 BOM), incorrect line endings (CRLF where LF is expected), or data truncation. Even when they appear to succeed, the resulting files may break parsers, linters, and downstream tooling.

---

## Section 2: Issue Creation Rules

### 2a. Improvement-First Decision Rule

When any agent discovers an out-of-scope or non-blocking improvement during its work:

- **< 1 day effort**: Address within the current task (or current PR if one is open) if the change is low-risk and does not expand scope significantly; otherwise defer.
- **> 1 day effort (significant)**: Create a follow-up GitHub issue **immediately** using `gh issue create`, then continue with in-scope work. Do not block the current PR on the deferred improvement.

### 2b. Priority Label Requirement

Every `gh issue create` command run by any agent **MUST** include a `--label` flag specifying a priority. Issues created without a priority label are non-compliant.

```powershell
# REQUIRED — always include a priority label:
gh issue create --title "..." --body "..." --label "priority: medium"

# WRONG — missing priority label:
gh issue create --title "..." --body "..."
```

> **Prerequisite — Priority labels must exist in the target repository.**
> If they do not yet exist, run these commands once per repository:
>
> ```powershell
> gh label create "priority: high"   --color "#D93F0B" --description "Critical — must fix this sprint"
> gh label create "priority: medium" --color "#FBCA04" --description "Strong improvement — schedule soon"
> gh label create "priority: low"    --color "#0075CA" --description "Nice-to-have — defer or batch"
> ```

#### Priority Labels

| Label              | Description                           | When to use                                                   |
| ------------------ | ------------------------------------- | ------------------------------------------------------------- |
| `priority: high`   | Critical — highest impact, must fix   | Correctness bugs, security issues, broken builds              |
| `priority: medium` | Strong improvement — depth and polish | Deferred improvements, notable refactors, non-urgent features |
| `priority: low`    | Nice-to-have — cosmetic or optional   | Cosmetic, optional, or speculative work                       |

**Default for automatically-created follow-up issues**: `priority: medium`
