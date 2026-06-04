---
name: gw-hotfix
description: Apply Liam's production hotfix path from main through patch release and sync-back to dev. Use when the issue is already live in production, the user mentions urgent repair, or asks whether a bug should be handled as a hotfix instead of a normal fix branch.
---

# Hotfix Workflow

Read first:

- `../../references/policy.md`
- `../../references/branch-matrix.md`

## Workflow

1. Confirm the issue is production-facing
2. Use `hotfix/*`
3. Branch from `main`
4. Merge back to `main`
5. Tag patch release on `main`
6. Sync the fix back to `dev`

## Output

Provide:

- hotfix confirmation
- suggested branch name
- base branch and merge target
- post-release sync reminder

