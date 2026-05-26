---
phase: 04-superpowers-codex-claude-code
plan: 03
subsystem: scripts
tags: [install, symlink, refactor, powershell]
requires: []
provides:
  - "symlink-based install.ps1 (D-07)"
  - "simplified common.ps1 (no file-copy logic)"
  - "updated delegation scripts (link_codex_global_skills, update)"
affects:
  - scripts/install.ps1
  - scripts/common.ps1
  - scripts/link_codex_global_skills.ps1
  - scripts/update.ps1
tech-stack:
  added: []
  patterns:
    - "Directory junction (mklink /J) for Codex skills deployment"
    - "Plugin-as-repo-root for Claude Code (/plugin install)"
    - "Immutability: symlink preserves single source of truth"
key-files:
  created: []
  modified:
    - scripts/install.ps1 (rewritten, 33 -> 112 lines)
    - scripts/common.ps1 (simplified, 181 -> 65 lines)
    - scripts/link_codex_global_skills.ps1 (updated, 20 -> 36 lines)
    - scripts/update.ps1 (updated, 55 -> 51 lines)
decisions:
  - "mklink /J (directory junction) chosen over file-level symlinks to avoid Codex bug #17344"
  - "Claude Code installation reduced to user guidance (/plugin install) — repo is its own plugin directory"
  - "CleanLegacy covers three legacy artifact locations: ~/.codex/skills/, ~/.claude/commands/, ~/.agents/skills/"
  - "common.ps1 metadata now writes to ~/.liam-git-workflow/ (user profile) instead of $ClaudeHome-based path"
metrics:
  duration: ""
  completed_date: ""
---

# Phase 04 Plan 03: 安装脚本 symlink 重写 Summary

将 install.ps1 从文件复制模型重写为 symlink + plugin manifest 模型，简化 common.ps1 移除文件复制函数，更新 link_codex_global_skills.ps1 和 update.ps1 以兼容新安装模型。

## Tasks Executed

| # | Task | Status | Commit |
|---|------|--------|--------|
| 1 | 重写 install.ps1 — symlink 模型安装脚本 | Done | f6b2cfb |
| 2 | 简化 common.ps1 — 移除文件复制函数 | Done | bbe0097 |
| 3 | 更新 link_codex_global_skills.ps1 和 update.ps1 | Done | 4f8a92f |

### Task 1: install.ps1 Rewrite

**Before:** 33-line script delegating to Install-LiamGitWorkflowCodex and Install-LiamGitWorkflowClaude (file-copy model).

**After:** 112-line script implementing symlink + plugin model:
- Codex: `mklink /J` creates directory junction `~/.agents/skills/liam-git-workflow -> repo/skills/`
- Claude Code: No file operations; user guided to run `/plugin install <repo-path>` or `claude --plugin-dir <repo-path>`
- `-CleanLegacy` flag cleans up three legacy artifact locations
- `-SkipCodex` and `-SkipClaude` preserved for backward compatibility

### Task 2: common.ps1 Simplification

**Removed functions (5):**
- `Copy-DirectoryTree` — file-copy, replaced by symlink
- `Copy-FileWithReplacements` — path rewriting, banned by D-03
- `Convert-ToForwardSlashPath` — only used by removed functions
- `Install-LiamGitWorkflowCodex` — old Codex install logic
- `Install-LiamGitWorkflowClaude` — old Claude Code install logic

**Kept functions (4):**
- `Resolve-LiamGitWorkflowRepoRoot`, `Get-LiamGitWorkflowVersion`, `Ensure-Directory`, `Reset-Path`

**Rewritten function (1):**
- `Write-LiamGitWorkflowInstallMetadata` — removed `$CodexHome`/`$ClaudeHome` params, added `installModel` field, metadata root now `$env:USERPROFILE\.liam-git-workflow\`

**Result:** 181 lines reduced to 65 lines.

### Task 3: Delegation Script Updates

**link_codex_global_skills.ps1:** Removed `-CodexHome` parameter, now uses `-CodexSkillsHome` (defaults to `~/.agents/skills`) and forwards `-SkipClaude` to install.ps1.

**update.ps1:** Removed `$CodexHome` and `$ClaudeHome` parameters. Delegate call now passes only `-RepoRoot`. `-SkipCodex`/`-SkipClaude` forwarding and `PullLatest` git pull logic preserved.

## Verification Results

| Check | Result |
|-------|--------|
| install.ps1 syntax | PASS |
| common.ps1 dot-source + function inventory | PASS |
| link_codex_global_skills.ps1 syntax | PASS |
| update.ps1 syntax | PASS |
| No Copy-Item/Copy-DirectoryTree in install.ps1 | PASS |
| mklink /J present in install.ps1 | PASS (4 occurrences) |
| 5 deleted functions absent from common.ps1 | PASS |
| installModel field in common.ps1 | PASS |
| codexHome/claudeHome fields removed | PASS |
| Template placeholders removed from common.ps1 | PASS |

## Deviations from Plan

None. Plan executed exactly as written with one technical adaptation: file encoding required UTF-8 BOM for PowerShell 5.1 compatibility on Windows (applied via `[System.Text.UTF8Encoding] $true`).

## Known Stubs

None. All scripts are fully functional — no hardcoded empty values or placeholder text.

## Threat Flags

None. All security surface is covered by the plan's existing threat model (T-04-11 through T-04-16).

## Self-Check: PASSED

- All 4 modified files exist on disk
- All 3 commits (f6b2cfb, bbe0097, 4f8a92f) exist in git log
- All acceptance criteria verified
- All PowerShell syntax checks passed
