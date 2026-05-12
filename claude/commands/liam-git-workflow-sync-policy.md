---
description: Audit local Git configuration against Liam's policy.
---

Read:

- `@{{REFERENCES_ROOT}}/policy.md`

Use the audit script when helpful:

- `{{SCRIPTS_ROOT}}/audit_git_config.ps1`

The user wants policy alignment guidance:

`$ARGUMENTS`

Workflow:

1. compare current git config against policy
2. report matches and drift
3. suggest exact alignment commands
4. do not change config automatically unless explicitly asked

Output:

- current vs expected values
- drift summary
- exact `git config --global ...` commands to align
