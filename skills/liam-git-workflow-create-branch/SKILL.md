---
name: liam-git-workflow-create-branch
description: Choose the correct Git branch type, base branch, merge target, and normalized branch name for Liam's workflow. Use when the user asks to create a branch, name a branch, decide between feature/fix/hotfix/chore/docs/refactor, or determine whether to branch from dev or main.
---

# Create Branch

Read first:

- `../../references/policy.md`
- `../../references/branch-matrix.md`
- `../../references/scenarios.md`

## Workflow

1. Classify the request into `feature`, `fix`, `hotfix`, `chore`, `docs`, `refactor`, or `release`
2. Choose the base branch
3. Suggest a normalized branch name
4. State the future merge target

## Guardrails

- Production issue -> `hotfix/*` from `main`
- Pre-release bug -> `fix/*` from `dev`
- New capability -> `feature/*` from `dev`
- Do not send `feature/*` or `fix/*` directly to `main`

## Output

Provide:

- detected branch type
- base branch
- suggested branch name
- merge target
- optional Git command example

