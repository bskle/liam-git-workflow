# Liam Git Workflow

Personal Codex plugin for Liam's Git workflow.

## Goal

Provide one consistent Codex entrypoint for Liam's Git rules and common actions:

- choose the right branch type
- create a branch from the right base
- draft Chinese Conventional Commits
- sync a work branch with `dev` or `main`
- finish work and prepare the next Git step
- handle production hotfix flow
- prepare release flow
- audit local Git config against policy

## Codex Usage

Primary entry:

```text
$liam-git-workflow
创建一个线上bug修复的分支，修复login出现的网络问题
```

Help:

```text
$liam-git-workflow-help
```

Direct entries:

```text
$liam-git-workflow-create-branch
$liam-git-workflow-commit
$liam-git-workflow-sync-branch
$liam-git-workflow-finish
$liam-git-workflow-hotfix
$liam-git-workflow-release
$liam-git-workflow-sync-policy
```

## Command Model

- In Codex, prefer `$liam-git-workflow`
- Do not rely on `$Liam Git Workflow`
- The plugin name follows lower-case hyphen-case for trigger stability

## Rule Sources

- [policy.md](D:/liam/project/others/20260511_liam_git_workflow/references/policy.md): canonical workflow policy
- [branch-matrix.md](D:/liam/project/others/20260511_liam_git_workflow/references/branch-matrix.md): branch decision rules
- [commit-rules.md](D:/liam/project/others/20260511_liam_git_workflow/references/commit-rules.md): commit conventions
- [pr-rules.md](D:/liam/project/others/20260511_liam_git_workflow/references/pr-rules.md): PR and merge expectations
- [scenarios.md](D:/liam/project/others/20260511_liam_git_workflow/references/scenarios.md): common examples

## Repository Layout

```text
.codex-plugin/
.agents/plugins/
skills/
references/
scripts/
```

## Install Notes

This repository is designed to be used as a local Codex plugin repository. The plugin manifest is at:

- [plugin.json](D:/liam/project/others/20260511_liam_git_workflow/.codex-plugin/plugin.json)

The local marketplace entry is at:

- [marketplace.json](D:/liam/project/others/20260511_liam_git_workflow/.agents/plugins/marketplace.json)

## Global Skill Sync

To expose these skills through the Codex global skill library while keeping this repository as the single source of truth, run:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\link_codex_global_skills.ps1
```

This creates junctions under `C:\Users\250707012\.codex\skills\` for each `liam-git-workflow*` skill directory, plus a shared `C:\Users\250707012\.codex\references` junction that keeps the existing relative reference paths working.

## Current Scope

This first pass focuses on policy, routing guidance, and repeatable prompts. It does not yet include command wrappers that automatically perform risky Git actions without confirmation.
