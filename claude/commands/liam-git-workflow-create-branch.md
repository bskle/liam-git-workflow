---
description: Choose the correct branch type, base branch, merge target, and branch name for Liam's workflow.
---

Read:

- `@{{REFERENCES_ROOT}}/policy.md`
- `@{{REFERENCES_ROOT}}/branch-matrix.md`
- `@{{REFERENCES_ROOT}}/scenarios.md`

The user wants branch guidance:

`$ARGUMENTS`

Workflow:

1. classify the request as `feature`, `fix`, `hotfix`, `chore`, `docs`, `refactor`, or `release`
2. choose the correct base branch
3. suggest a normalized branch name
4. state the future merge target

Guardrails:

- production issue -> `hotfix/*` from `main`
- pre-release bug -> `fix/*` from `dev`
- new capability -> `feature/*` from `dev`
- do not send `feature/*` or `fix/*` directly to `main`

Output:

- detected branch type
- base branch
- suggested branch name
- merge target
- optional git command example
