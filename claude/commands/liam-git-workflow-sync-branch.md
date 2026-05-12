---
description: Sync a working branch with the correct base branch under Liam's policy.
---

Read:

- `@{{REFERENCES_ROOT}}/policy.md`
- `@{{REFERENCES_ROOT}}/branch-matrix.md`

The user wants sync guidance:

`$ARGUMENTS`

Workflow:

1. identify the current branch category
2. choose the correct upstream base branch
3. recommend the safest sync path
4. remind about verification after conflicts

Guardrails:

- prefer `git pull --rebase`
- do not force push unless the user explicitly authorizes it
- do not push directly to `main`

Output:

- current branch type
- expected base branch
- recommended sync commands
- follow-up verification checklist
