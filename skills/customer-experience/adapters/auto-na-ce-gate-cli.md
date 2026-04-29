---
name: auto-na-ce-gate-cli
provides: ce-gate-cli
applies-when: not changeset.touchesCliSurface()
---

# Auto N/A CE Gate CLI

Writes or represents a not-applicable credit for `ce-gate-cli` when the predicate matches.
