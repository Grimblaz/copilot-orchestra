---
description: Invoke Solution-Designer — technical design exploration with 3-pass adversarial challenge.
argument-hint: "[issue number]"
---

Dispatch the `solution-designer` subagent to do technical design exploration for the provided issue.

**Pre-flight**:

1. Require an issue number (the subagent needs a durable record to update).
2. If the issue body does not yet have customer framing (`<!-- experience-owner-complete-{ID} -->` marker), note that and ask the user whether to run `/experience` first or to proceed without upstream framing.

**Dispatch**:

Use the `Agent` tool with:

- `subagent_type: solution-designer`
- `description`: one short phrase describing the design task
- `prompt`: the issue number plus any upstream-framing context

The subagent will read `agents/Solution-Designer.agent.md` for its full methodology, run the 3-pass non-blocking design challenge, and persist the design in the issue body with a `<!-- design-phase-complete-{ID} -->` comment marker.

ARGUMENTS: $ARGUMENTS
