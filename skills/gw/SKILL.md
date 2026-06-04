---
name: gw
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
- `../../references/remote-diagnostics.md`

## Routing Rules

- For any commit-related request, re-read `policy.md` and `commit-rules.md` before answering
- If the request asks what commands or entries exist, route to `gw-help`
- If the request asks to create or name a branch, route to `gw-create-branch`
- If the request asks to commit changes, route to `gw-commit`
- If the request asks to sync with latest base, route to `gw-sync`
- If the request asks how to wrap up or what to do next with a finished branch, route to `gw-finish`
- If the request is about a production issue, route to `gw-hotfix`
- If the request is about tagging or merging `dev` into `main`, route to `gw-release`
- If the request asks to audit local Git policy or global config, route to `gw-sync-policy`
- If the request describes a remote operation failure (push/pull/fetch/ls-remote returning errors like "Authentication failed", "Could not resolve host", "Connection timed out", "protected branch", "repository not found", "Permission denied") or asks to diagnose remote connectivity problems, route to `gw-diagnose`
- If a remote Git operation (`push`, `pull`, `fetch`, `ls-remote`) fails during command execution with a non-zero exit status, stop the current action and route to `gw-diagnose` for structured diagnosis before any retry

## Response Style

- State the detected intent in one sentence
- State the chosen branch type, base branch, merge target, or commit shape
- Repeat the key commit rules at the action point: use Conventional Commits, subject must be Chinese, and draft 1 to 3 Chinese candidates before any commit runs
- When the action is risky, ask for confirmation before executing Git commands
- Prefer Codex trigger names like `$gw-create-branch`
- Do not recommend `$Liam Git Workflow`
- When a remote operation fails, do not retry the same command immediately — first route to the diagnostic skill, then apply the structured recommendation

