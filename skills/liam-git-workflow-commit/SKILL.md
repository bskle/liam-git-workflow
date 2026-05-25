---
name: liam-git-workflow-commit
description: Draft Chinese Conventional Commit messages for Liam's workflow and check whether the current change set is mixed. Use when the user asks to commit current changes, wants a commit title, or needs help choosing feat/fix/docs/chore/refactor/test/build/ci/perf/revert.
---

# Commit Workflow

Read first:

- `../../references/policy.md`
- `../../references/commit-rules.md`

## Workflow

1. Read the staged diff before drafting messages.
2. Re-read `policy.md` and `commit-rules.md` immediately before choosing the final message.
3. Infer likely change category from the user's description and staged diff.
4. Choose the best commit type.
5. Choose a compact English scope.
6. Draft 1 to 3 Chinese commit messages.
7. Warn if the described work sounds mixed or too broad.
8. Stop and regenerate if the final subject does not contain Chinese characters.
9. Before executing `git commit`, restate the exact final message that will be used.

## Output

Provide:

- recommended type
- recommended scope
- final recommended commit message
- 1 or 2 alternate commit messages if useful
- explicit confirmation that the message follows the Chinese Conventional Commit rule

