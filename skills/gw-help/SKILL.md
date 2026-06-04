---
name: liam-git-workflow-help
description: Show the available Liam Git Workflow entries, when to use each one, and example prompts. Use when the user asks for help, forgets an entry name, or wants to know whether the main entry can route requests automatically.
---

# Liam Git Workflow Help

List the available entries:

- `$liam-git-workflow`
- `$liam-git-workflow-help`
- `$liam-git-workflow-create-branch`
- `$liam-git-workflow-commit`
- `$liam-git-workflow-sync-branch`
- `$liam-git-workflow-finish`
- `$liam-git-workflow-hotfix`
- `$liam-git-workflow-release`
- `$liam-git-workflow-sync-policy`
- `$liam-git-workflow-remote-diagnose`

Explain:

- `$liam-git-workflow` is the main natural-language entry
- users do not need to specify a sub-entry when the main entry is enough
- the stable trigger format is lower-case hyphen-case

Give 3 short examples:

- create a production fix branch
- commit current changes
- check Git policy drift

