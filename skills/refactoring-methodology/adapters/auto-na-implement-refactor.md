---
name: auto-na-implement-refactor
provides: implement-refactor
applies-when: not changeset.touchedAreaHasRefactorableDebt()
---

# Auto N/A Implement Refactor

Writes or represents a not-applicable credit for `implement-refactor` when the predicate matches.
