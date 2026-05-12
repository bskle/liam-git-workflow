---
name: liam-git-workflow-commit
description: Draft Chinese Conventional Commit messages for Liam's workflow and check whether the current change set is mixed. Use when the user asks to commit current changes, wants a commit title, or needs help choosing feat/fix/docs/chore/refactor/test/build/ci/perf/revert.
---

# Commit Workflow

Read first:

- `../../references/policy.md`
- `../../references/commit-rules.md`

## Workflow

1. Infer likely change category from the user's description
2. Choose the best commit type
3. Choose a compact English scope
4. Draft 1 to 3 Chinese commit messages
5. Warn if the described work sounds mixed or too broad

## Output

Provide:

- recommended type
- recommended scope
- final recommended commit message
- 1 or 2 alternate commit messages if useful

