---
name: auto-na-ce-gate-canvas
provides: ce-gate-canvas
applies-when: not changeset.touchesCanvasSurface()
---

# Auto N/A CE Gate Canvas

Writes or represents a not-applicable credit for `ce-gate-canvas` when the predicate matches.
