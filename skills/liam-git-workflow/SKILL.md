---
name: liam-git-workflow
description: Route natural-language Git workflow requests for Liam's personal main/dev model. Use when the user wants one Git entrypoint in Codex for branch creation, commit drafting, branch syncing, finishing work, hotfixes, releases, or Git policy checks without remembering a specific sub-entry.
---

# Liam Git Workflow

Use this as the default entrypoint.

## Load First

Read:

- `../../references/policy.md`
- `../../references/branch-matrix.md`
- `../../references/commit-rules.md`
- `../../references/pr-rules.md`
- `../../references/scenarios.md`

## Routing Rules

- For any commit-related request, re-read `policy.md` and `commit-rules.md` before answering
- If the request asks what commands or entries exist, route to `liam-git-workflow-help`
- If the request asks to create or name a branch, route to `liam-git-workflow-create-branch`
- If the request asks to commit changes, route to `liam-git-workflow-commit`
- If the request asks to sync with latest base, route to `liam-git-workflow-sync-branch`
- If the request asks how to wrap up or what to do next with a finished branch, route to `liam-git-workflow-finish`
- If the request is about a production issue, route to `liam-git-workflow-hotfix`
- If the request is about tagging or merging `dev` into `main`, route to `liam-git-workflow-release`
- If the request asks to audit local Git policy or global config, route to `liam-git-workflow-sync-policy`

## Response Style

- State the detected intent in one sentence
- State the chosen branch type, base branch, merge target, or commit shape
- Repeat the key commit rules at the action point: use Conventional Commits, subject must be Chinese, and draft 1 to 3 Chinese candidates before any commit runs
- When the action is risky, ask for confirmation before executing Git commands
- Prefer Codex trigger names like `$liam-git-workflow-create-branch`
- Do not recommend `$Liam Git Workflow`

