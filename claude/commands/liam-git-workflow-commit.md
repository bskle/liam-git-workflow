---
description: Draft Chinese Conventional Commit messages for the current change set.
---

Read:

- `@{{REFERENCES_ROOT}}/policy.md`
- `@{{REFERENCES_ROOT}}/commit-rules.md`

Use the user's request plus current repository context to draft commit guidance:

`$ARGUMENTS`

Workflow:

1. read the staged diff before drafting messages
2. re-read the commit rules immediately before choosing the final message
3. infer the likely change category
4. choose the best commit type
5. choose a compact English scope
6. draft 1 to 3 Chinese commit messages
7. warn if the change set sounds mixed or too broad
8. stop and regenerate if the final subject does not contain Chinese characters
9. before executing git commit, restate the exact final message

Output:

- recommended type
- recommended scope
- final recommended commit message
- 1 or 2 alternate commit messages when useful
- explicit confirmation that the message follows the Chinese Conventional Commit rule
