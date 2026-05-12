---
description: Handle a production hotfix under Liam's main/dev workflow.
---

Read:

- `@{{REFERENCES_ROOT}}/policy.md`
- `@{{REFERENCES_ROOT}}/scenarios.md`

The user is dealing with a production issue:

`$ARGUMENTS`

Workflow:

1. confirm this is a production incident
2. branch from `main` using `hotfix/*`
3. suggest the minimum safe fix path
4. remind about regression coverage, merge back to `main`, tagging, and syncing back to `dev`

Output:

- branch type
- base branch
- suggested branch name
- merge and back-sync steps
