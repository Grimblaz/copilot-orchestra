# Design: Plug-and-Play Usability (Issue #20)

## Summary

Overhauled the new-user experience so that cloning the template is near-zero-config. Previously, users had to create multiple files from scratch before any agents would work. Now the template ships ready to use.

## Problem Statement

1. `copilot-instructions.md` and `architecture-rules.md` were required but not shipped — users wrote them from scratch
2. 15 agents with no guidance on which to use when
3. No interactive setup or guided first-run experience
4. Spring Boot examples didn't help Node.js or Python developers

## Design Decisions

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| D1 | Default config files | Pre-create with TODO markers | Agents work immediately on clone; users fill in markers |
| D2 | Setup wizard | `/setup` prompt (`.github/prompts/setup.prompt.md`) | Single command generates both config files interactively |
| D3 | Plan-Architect | **Removed entirely** | Issue-Planner is a strict superset; 0 remaining references |
| D4 | Agent visibility | `user-invokable: false` on 8 internal agents | Hides noise from picker; global use via `chat.agentFilesLocations` |
| D5 | Multi-stack examples | Added Node.js/TypeScript + Python alongside Spring Boot | Reduces copy-wrong-example friction |
| D6 | Quick Start | 2 steps: clone → `/setup` or manual TODO markers | From 4-step process to 2 |
| D7 | Decision aid | "I want to..." table in README | Users find the right agent without reading docs |
| D8 | Code-Conductor naming | Description already clear — no change needed | Pre-existing |
| D9 | Auto-commit | All auto-commit instructions removed from agents | Pre-existing |

## Implementation Changes

### Files Created

- `.github/copilot-instructions.md` — skeleton with `<!-- TODO: ... -->` markers
- `.github/architecture-rules.md` — skeleton with `<!-- TODO: ... -->` markers
- `.github/prompts/setup.prompt.md` — interactive setup wizard (`agent: ask`)
- `examples/nodejs-typescript/copilot-instructions.md`
- `examples/nodejs-typescript/architecture-rules.md`
- `examples/nodejs-typescript/README.md`
- `examples/python/copilot-instructions.md`
- `examples/python/architecture-rules.md`
- `examples/python/README.md`

### Files Modified

- `.github/agents/Plan-Architect.agent.md` — **deleted**
- 8 agent files — added `user-invokable: false` frontmatter
- `.github/prompts/start-issue.md` — updated Plan-Architect → Issue-Planner refs
- `README.md` — rewritten: 2-step Quick Start, decision table, global setup docs (198 lines vs 324)
- `CUSTOMIZATION.md` — simplified (68 lines vs 229)
- `CONTRIBUTING.md` — added `chat.agentFilesLocations` + `chat.useAgentSkills` docs

## Agents: Visible vs Hidden

### Visible (6) — appear in VS Code chat picker

Issue-Designer, Issue-Planner, Code-Conductor, Code-Critic, Code-Review-Response, Janitor

### Hidden (8) — `user-invokable: false`, available as subagents

Code-Smith, Test-Writer, Doc-Keeper, Process-Review, Refactor-Specialist, Research-Agent, Specification, UI-Iterator

## Acceptance Criteria Verification

| AC | Status |
|----|--------|
| Clone → agent within 2 min, no file creation needed | ✅ Skeleton files ship with repo |
| Default config files functional out of box | ✅ Skeletons present; agents work with placeholder context |
| Clear TODO markers guide personalization | ✅ Every section has `<!-- TODO: ... -->` guidance |
| Decision tree maps tasks to agents | ✅ "I want to..." table in README |
| README Quick Start: 2 steps | ✅ Clone → `/setup` or manual TODOs |
| Node.js/TypeScript + Python examples | ✅ `examples/nodejs-typescript/` + `examples/python/` |
| Setup prompt generates config from answers | ✅ `.github/prompts/setup.prompt.md` |
| `.vscode/settings.json` visibility | ⚠️ Resolution: `user-invokable: false` + `chat.agentFilesLocations` docs (no workspace settings API exists) |
| Plan-Architect removed, all refs updated | ✅ 0 references remain |
| No auto-commit instructions | ✅ Pre-existing |
| Code-Conductor description clear | ✅ Pre-existing |

## Review Findings Addressed

From Code-Critic adversarial review:

- **F1 (CRITICAL)**: Fixed README invocation `@setup` → `/setup` (prompt files are slash commands)
- **F2 (REJECTED)**: `agent: ask` is correct per VS Code docs; `mode: ask` is the deprecated field
- **F3 (DEFERRED)**: Skeleton self-contamination for template contributors → Issue #34
- **F4 (FIXED)**: Skeleton hints now reference all 3 examples (Spring Boot, TypeScript, Python)
- **F5 (FIXED)**: Added `chat.useAgentSkills` settings snippet to CONTRIBUTING.md
- **F6 (FIXED)**: Example READMEs corrected from `@workspace /setup` → `/setup`
- **F7 (FIXED)**: HTML comments in bash code fences replaced with `# e.g., ...` style

## CE Gate

Not applicable — documentation/configuration change only. No runtime code or customer-facing UI surface. Manual walkthrough validates end-to-end.

## Follow-up Issues

- **#34**: Skeleton `copilot-instructions.md` self-contaminates template repo context for contributors
