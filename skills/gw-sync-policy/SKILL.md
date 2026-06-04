---
name: gw-sync-policy
description: Audit local Git configuration against Liam's workflow policy and report drift. Use when the user asks whether global git config matches policy, wants recommended git config commands, or needs a checklist before aligning a machine to the workflow.
---

# Sync Policy

Read first:

- `../../references/policy.md`

Use the audit script when available:

- `../../scripts/audit_git_config.ps1`

## Workflow

1. Compare current global Git config against policy
2. Report matches and drift
3. Suggest exact alignment commands
4. Do not change config automatically unless explicitly asked

## Output

Provide:

- current vs expected values
- drift summary
- exact `git config --global ...` commands to align

