---
name: auto-na-ce-gate-browser
provides: ce-gate-browser
applies-when: not changeset.touchesBrowserSurface()
---

# Auto N/A CE Gate Browser

Writes or represents a not-applicable credit for `ce-gate-browser` when the predicate matches.
