---
name: liam-git-workflow-sync-branch
description: Decide how the current work branch should sync with its base branch in Liam's workflow. Use when the user wants to pull latest changes, rebase onto dev or main, resolve branch drift, or asks how to sync a feature, fix, or hotfix branch safely.
---

# Sync Branch

Read first:

- `../../references/policy.md`
- `../../references/branch-matrix.md`

## Workflow

1. Infer the current branch family
2. Choose the expected base branch
3. Prefer `git pull --rebase` semantics
4. Warn about uncommitted changes and conflict handling

## Output

Provide:

- expected upstream branch
- recommended sync approach
- conflict caution
- optional command sequence

