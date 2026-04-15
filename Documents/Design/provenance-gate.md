# Design: First-Contact Provenance Gate

## Purpose

Prevent pipeline agents from blindly executing existing GitHub issues that may contain misdiagnosed root causes, inappropriate solution mechanisms, or inaccurate scope. When a user-invocable agent picks up an issue without an upstream handoff in the current session (cold pickup), the gate forces a structured assessment before the pipeline commits resources.

## Scope

The gate applies to all user-invocable agents (`user-invocable: true`) when they receive a request referencing an existing GitHub issue and no warm-handoff markers exist for that issue in the current session. Internal subagents dispatched by Code-Conductor are excluded — they already operate within an assessed session context.

---

## Design Decisions

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| D1 | Persistence mechanism | Session memory + HTML marker fallback | Zero new infrastructure. Primary marker `<!-- first-contact-assessed-{ID} -->` is posted as a GitHub issue comment via `mcp_github_add_issue_comment`. If the API call fails, session memory records the assessment instead. Warm-handoff detection checks both session memory (`plan-issue-{ID}`, `design-issue-{ID}`) and GitHub comments (`<!-- experience-owner-complete-{ID} -->`, `<!-- design-phase-complete-{ID} -->`) |
| D2 | Assessment protocol | Three-question structured evaluation | (1) Root cause vs. symptom — does the issue identify an actual mechanism failure or describe a behavioral observation? (2) Mechanism fitness — does the proposed solution align with project conventions per `copilot-instructions.md` and `architecture-rules.md`? (3) Scope accuracy — do the listed files, systems, and acceptance criteria match the identified root cause? All three are project-aware, not just issue-text analysis |
| D3 | Developer interaction | Inline conversation + `askQuestions` gate | Three options: "I wrote this / I'm fully briefed" (fast-path dismiss), "Assessment looks right — proceed with caution" (acknowledged proceed), "Needs rework — stop here" (abort). The marker is posted for all responses except "Needs rework". This keeps the gate zero-friction for warm pickups that escaped marker detection |
| D4 | Delivery pattern | `copilot-instructions.md` compact trigger + `provenance-gate.instructions.md` detailed protocol | Follows the session-startup delivery pattern. VS Code `applyTo` targets files being edited, not agent invocations — so the trigger must live in the always-loaded `copilot-instructions.md`. The compact trigger handles Steps 1–4 (extract ID, check markers, check dedup, self-filter) inline; Step 5 loads the full protocol from the instructions file |

---

## Delivery Pattern

The gate reuses the same two-tier delivery pattern as session-startup:

1. **Compact trigger** — embedded in `.github/copilot-instructions.md` under "First-Contact Provenance Gate". Contains the 6-step decision tree (extract issue ID → check warm-handoff → check prior assessment → self-filter → run assessment → record marker). This file is always loaded by VS Code regardless of which agent is active.
2. **Detailed protocol** — `.github/instructions/provenance-gate.instructions.md`. Contains the full three-question assessment procedure, developer gate presentation format, edge cases, and rationale. Loaded on demand at Step 5.

This pattern exists because of a VS Code platform constraint: instruction files use `applyTo` glob patterns that match files being edited, not agent invocations. The only file guaranteed to be in context for every agent interaction is `copilot-instructions.md`.

---

## Marker Lifecycle

The provenance gate introduces one new marker into the existing marker ecosystem:

| Marker | Written by | Written to | Purpose |
|--------|-----------|------------|---------|
| `<!-- first-contact-assessed-{ID} -->` | Any user-invocable agent (after gate passes) | GitHub issue comment (primary) or session memory (fallback) | Skip-on-re-invocation dedup — prevents the gate from re-firing |

Existing markers that the gate **reads** (but does not write):

| Marker | Meaning for gate |
|--------|-----------------|
| `plan-issue-{ID}` (session memory) | Warm handoff — skip gate |
| `design-issue-{ID}` (session memory) | Warm handoff — skip gate |
| `<!-- experience-owner-complete-{ID} -->` (GitHub comment) | Warm handoff — skip gate |
| `<!-- design-phase-complete-{ID} -->` (GitHub comment) | Warm handoff — skip gate |

---

## Known Limitations

1. **Plugin distribution gap** — Consumer repos using Copilot Orchestra as a plugin (copied agent files without `.github/instructions/`) will not have `provenance-gate.instructions.md`. The compact trigger includes inline minimal fallback guidance, but the full three-question protocol requires the instructions file. This is a shared limitation with other instruction files (e.g., `session-startup.instructions.md`). **Mitigation (issue #350)**: The gate trigger is now distributed in all 3 example templates (`examples/*/copilot-instructions.md`) for template-based adoption, and `CUSTOMIZATION.md` documents the trigger-section prerequisite so plugin users are aware of the requirement and degradation behavior.

2. **No behavioral enforcement** — The gate is prose-enforced by LLM agents, not programmatically enforced. An agent may skip or abbreviate the assessment. The contract test in `handoff-persistence-contract.Tests.ps1` validates structural presence of the trigger wording in `copilot-instructions.md`, but cannot enforce runtime behavior. Consistent with all other pipeline gates.

3. **Model-dependent assessment quality** — The three-question assessment relies on LLM judgment. Different models and context states produce varying depth. The gate mitigates this by surfacing findings to the developer via `askQuestions` rather than auto-gating — developer judgment is the ultimate authority.

---

## Implementation

| File | Role |
|------|------|
| `.github/copilot-instructions.md` | Compact trigger (Steps 1–6 decision tree) |
| `.github/instructions/provenance-gate.instructions.md` | Full three-question assessment protocol and edge cases |
| `.github/scripts/Tests/handoff-persistence-contract.Tests.ps1` | Contract tests: marker format consistency, trigger wording presence, behavioral assertions |
| `examples/*/copilot-instructions.md` | Consumer template distribution — verbatim copy of the compact trigger for template-based adoption |
| `CUSTOMIZATION.md` | Plugin-user awareness — documents gate requirements and degradation behavior |
