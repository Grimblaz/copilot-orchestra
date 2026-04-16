# Design: Skills Framework

## Summary

The skills framework provides domain-specific knowledge modules loaded on demand by agents from `.github/skills/`. Under the thin-agents/fat-skills direction for issue #344, skills hold reusable methodology and protocol content, while agents retain orchestration boundaries such as routing, identity, trigger points, and commit authority. The repository currently ships 19 skills; issue #344 expands that inventory to 32 by moving methodology out of agents without changing agent interfaces. Hub skills may be extended by project-specific supplement skills (named `{project}-{hub-skill-name}`) that layer additional constraints on top of their defaults.

---

## Design Decisions

| # | Decision | Choice | Rationale |
|---|----------|--------|-----------|
| D1 | Migration target | `.github/skills/` (from `.claude/skills/`) | VS Code 1.108 introduced Agent Skills with `.github/skills/` as the standard location (`chat.useAgentSkills` setting); clean break from the legacy path |
| D2 | Content sync strategy | Cherry-pick improvements from upstream (Organizations-of-Elos) | Most OoE skills became project-specific (game design references, hardcoded npm commands); the template versions are deliberately generic with `[CUSTOMIZE]` markers — wholesale replacement would make the template stack-specific |
| D3 | `webapp-testing` addition | Include | Playwright E2E testing is broadly applicable across web projects; content is generic enough for a template |
| D4 | `test-driven-development` rename | Rename from `tdd-workflow` | More descriptive name; matches OoE convention; aligns with standard terminology |
| D5 | `property-based-testing` addition | Include | Incremental rollout policy for randomized property verification alongside example-based tests |
| D6 | Supplement skill convention | `{project}-{hub-skill-name}` naming; hub skill is always loaded alongside supplement | Projects with unique visual identities, brand tokens, or component conventions beyond `[CUSTOMIZE]` markers benefit from a supplement that layers on top of the hub skill rather than forking it — preserving shared defaults while enabling project-specific customization |

---

## Boundary Rules For Issue #344

Issue #344 changes the skills boundary from "skills are reference material" to "skills are the home for reusable methodology." The split is:

- Agents keep orchestration: user-turn routing, handoffs, trigger placement, step ordering, commit decisions, issue-state transitions, and any identity-level stance that defines the agent's role.
- Skills keep methodology: reusable protocols, checklists, questioning patterns, validation ladders, evidence contracts, and decision heuristics that can be loaded by multiple agents.
- Concrete examples: the Code-Conductor step loop, CE Gate orchestration, and defect routing remain agent-owned; the validation ladder and review-reconciliation method move to skills. Test-Writer keeps delegation flow in the agent while shared testing method consolidates into `test-driven-development`.
- Portable trigger skills such as `session-startup`, `provenance-gate`, and `terminal-hygiene` remain skills; the logic for when an agent invokes them stays in the owning agent.
- `guidance-complexity` stays agent-only in this issue. It remains an architecture check enforced from agent/instruction surfaces rather than becoming a skill.

---

## Skill Inventory Direction

### Currently Shipped Inventory (19 Skills)

| Skill | Directory | Purpose |
|-------|-----------|---------|
| `bdd-scenarios` | `.github/skills/bdd-scenarios/` | Structured Given/When/Then scenario authoring with ID traceability and CE Gate coverage gap detection |
| `brainstorming` | `.github/skills/brainstorming/` | Structured Socratic questioning for exploring ideas and solutions |
| `frontend-design` | `.github/skills/frontend-design/` | Guide for creating distinctive UI designs that avoid generic templates |
| `parallel-execution` | `.github/skills/parallel-execution/` | Build-test orchestration protocol for choosing and running parallel or serial implementation lanes |
| `property-based-testing` | `.github/skills/property-based-testing/` | Incremental rollout policy for property-based testing that preserves readable example-based tests |
| `skill-creator` | `.github/skills/skill-creator/` | Guide for creating new skills in this system with proper frontmatter format |
| `software-architecture` | `.github/skills/software-architecture/` | Clean Architecture, SOLID principles, and architectural decision guidance |
| `systematic-debugging` | `.github/skills/systematic-debugging/` | 4-phase debugging process (Observe, Hypothesize, Test, Fix) for complex issues |
| `test-driven-development` | `.github/skills/test-driven-development/` | Test-Driven Development workflow guidance, quality standards, and practical patterns |
| `ui-testing` | `.github/skills/ui-testing/` | Resilient React component testing strategies focusing on user behavior |
| `verification-before-completion` | `.github/skills/verification-before-completion/` | Evidence-based verification checklist before marking work complete |
| `webapp-testing` | `.github/skills/webapp-testing/` | Playwright end-to-end testing guidance for web apps, with practical patterns and setup steps |
| `browser-canvas-testing` | `.github/skills/browser-canvas-testing/` | VS Code native browser tool behavior for canvas-based games (Phaser 3, etc.) |
| `code-review-intake` | `.github/skills/code-review-intake/` | Deterministic GitHub review intake workflow with ledger-based judgment |
| `post-pr-review` | `.github/skills/post-pr-review/` | Post-merge checklist for archiving, documentation, versioning, and release tagging |
| `process-troubleshooting` | `.github/skills/process-troubleshooting/` | Five-scenario workflow troubleshooting guide for diagnosing and fixing common orchestration failure patterns |
| `provenance-gate` | `.github/skills/provenance-gate/` | First-contact issue-framing assessment for cold pickups |
| `session-startup` | `.github/skills/session-startup/` | Automatic startup cleanup guard for new conversations |
| `terminal-hygiene` | `.github/skills/terminal-hygiene/` | Terminal and test execution guardrails for Copilot Orchestra workflows |

### Issue #344 Target Inventory (32 Skills)

Issue #344 adds 13 methodology-focused skills while keeping the existing 19-skill baseline and preserving agent interfaces.

| Planned skill | Source boundary |
|---------------|-----------------|
| `documentation-finalization` | Extract reusable documentation-finalization methodology from `Doc-Keeper.agent.md` |
| `specification-authoring` | Extract reusable specification authoring method from `Specification.agent.md` |
| `refactoring-methodology` | Extract reusable refactoring workflow from `Refactor-Specialist.agent.md` |
| `implementation-discipline` | Extract reusable implementation workflow from `Code-Smith.agent.md` |
| `research-methodology` | Extract reusable research workflow from `Research-Agent.agent.md` |
| `process-analysis` | Extract reusable process-analysis method from `Process-Review.agent.md` |
| `customer-experience` | Extract reusable customer-experience method from `Experience-Owner.agent.md` |
| `design-exploration` | Extract reusable design exploration method from `Solution-Designer.agent.md` |
| `plan-authoring` | Extract reusable planning method from `Issue-Planner.agent.md` |
| `adversarial-review` | Extract reusable prosecution methodology from `Code-Critic.agent.md` |
| `review-judgment` | Extract reusable review judgment method from `Code-Review-Response.agent.md` |
| `ui-iteration` | Extract reusable UI iteration method from `UI-Iterator.agent.md` |
| `validation-methodology` | Extract reusable validation methodology from `Code-Conductor.agent.md` |

---

## Cherry-Pick Strategy

| Skill | What was cherry-picked from upstream |
|-------|--------------------------------------|
| `skill-creator` | `.github/skills/` paths; VS Code 1.108 `chat.useAgentSkills` discovery info; "Minimal vs Full Skill" pattern; frontmatter validation table |
| `verification-before-completion` | "Iron Law" framing; "Rationalization Prevention" table; "Red Flags — STOP" patterns (genericized, not project-specific) |
| `test-driven-development` | Renamed from `tdd-workflow`; "Iron Law of TDD"; quality hierarchy table; verification checklist; anti-pattern references; `[CUSTOMIZE]` commands preserved; "Collection / Iteration Coverage" principle requiring 2-record scenarios for persistence-layer iteration functions |
| `brainstorming` | No content changes — template version already appropriate for a general template |
| `software-architecture` | No content changes — generic Clean Architecture/SOLID guidance preserved |
| `ui-testing`, `systematic-debugging`, `frontend-design` | Path references updated only |

---

## Skill File Format

Every skill lives at `.github/skills/{skill-name}/SKILL.md` with required YAML frontmatter:

```yaml
---
name: skill-name
description: What skill does. Use when {trigger conditions}. DO NOT USE FOR: {negative scenarios} (use {other-skill}).
---
```

Supporting files (e.g., `patterns.md`, `playwright-setup.md`) may live alongside `SKILL.md` in the same directory. Skills provide knowledge and procedural guidance — they must NOT contain agent orchestration logic.

For issue #344, "must NOT contain agent orchestration logic" means skills do not decide which agent speaks next, when a trigger fires, whether a commit occurs, or how Code-Conductor advances between plan steps. Skills may contain the reusable protocol an agent follows once the agent has decided to invoke that skill.

---

## Files Changed

| Action | File |
|--------|------|
| Moved | `.claude/skills/*` → `.github/skills/*` |
| Renamed | `.github/skills/tdd-workflow/` → `.github/skills/test-driven-development/` |
| Created | `.github/skills/webapp-testing/SKILL.md` |
| Created | `.github/skills/webapp-testing/patterns.md` |
| Created | `.github/skills/webapp-testing/playwright-setup.md` |
| Deleted | `.claude/` directory |
| Updated | Agent definitions — `.claude/skills/` → `.github/skills/` path references |
| Updated | `README.md`, `CUSTOMIZATION.md`, `CONTRIBUTING.md` — path + skill table |
| Updated | `.github/scripts/validate-architecture.ps1` — path reference |
| Updated | `.github/skills/README.md` — full rewrite |

---

## Acceptance Criteria

- `grep -r ".claude/skills" . --exclude-dir=Documents` returns zero results (excluding git history and this design doc)
- Each `SKILL.md` has valid frontmatter with `name` and `description`
- `validate-architecture.ps1` checks `.github/skills` path
- VS Code skill discovery works with `chat.useAgentSkills` enabled
- Current baseline is 19 skills, with issue #344 expanding the target inventory to 32 skills
