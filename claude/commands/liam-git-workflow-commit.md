---
description: Draft Chinese Conventional Commit messages for the current change set.
---

Read:

- `@{{REFERENCES_ROOT}}/policy.md`
- `@{{REFERENCES_ROOT}}/commit-rules.md`

Use the user's request plus current repository context to draft commit guidance:

`$ARGUMENTS`

Workflow:

1. infer the likely change category
2. choose the best commit type
3. choose a compact English scope
4. draft 1 to 3 Chinese commit messages
5. warn if the change set sounds mixed or too broad

Output:

- recommended type
- recommended scope
- final recommended commit message
- 1 or 2 alternate commit messages when useful
