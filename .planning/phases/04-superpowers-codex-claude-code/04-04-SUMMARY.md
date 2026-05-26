---
phase: 04-superpowers-codex-claude-code
plan: 04
subsystem: documentation
tags: [docs, readme, changelog, v0.3.0, plugin-install]
requires:
  - 04-01 (plugin infrastructure)
  - 04-02 (Codex config refinement)
  - 04-03 (install script rewrite)
provides:
  - README.md (v0.3.0 plugin-model docs)
  - CHANGELOG.md (v0.3.0 entry)
affects: []
tech-stack:
  added: []
  patterns: [symlink-install-model, plugin-manifest-registration, skill-tool-calling]
key-files:
  created: []
  modified:
    - README.md (79 insertions, 40 deletions — 7 sections rewritten)
    - CHANGELOG.md (13 insertions — v0.3.0 entry prepended)
decisions:
  - README 安装章节最终采用 "前置条件 -> Claude Code 安装 -> Codex 安装 -> 同时安装 -> 旧版本迁移" 五段结构
  - CHANGELOG v0.3.0 条目按影响力降序排列 (插件化 -> manifest -> 废弃 -> 重写 -> 修正 -> 文档)
metrics:
  duration: minimal
  completed: 2026-05-26
---

# Phase 04 Plan 04: README 和 CHANGELOG 文档更新 Summary

将 README.md 和 CHANGELOG.md 更新到 v0.3.0，反映 Phase 04 插件化安装模型和全部变更。

## Execution Summary

**Tasks executed:** 2/2
**Deviations:** Minor acceptance criteria divergence (documented below)
**Auth gates:** None

## Commit Log

| Task | Commit | Message |
|------|--------|---------|
| 1 | `5ca618b` | docs(04-04): 重写 README 安装/使用/目录章节，反映 v0.3.0 插件化模型 |
| 2 | `46c0e7b` | docs(04-04): 添加 CHANGELOG.md v0.3.0 条目，记录 Phase 04 全部变更 |

## Task Details

### Task 1: 重写 README.md

重写 7 个章节，将文档从 0.2.0 文件复制模型升级到 0.3.0 插件化模型：

1. **运行时支持** — Claude Code 描述改为 `.claude-plugin/plugin.json` 标准插件安装
2. **在 Codex 中使用** — 添加 Skill tool 调用说明，补充 `$liam-git-workflow-remote-diagnose`
3. **在 Claude Code 中使用** — slash commands (`/liam-git-workflow:...`) 改为 Skill tool 列表
4. **安装** — 整节重写：前置条件、Claude Code `/plugin install`、Codex symlink 脚本、双平台安装、CleanLegacy 迁移
5. **更新** — git pull 即更新，symlink 模型无需重新安装
6. **目录结构** — 添加 `.claude-plugin/` 和 `hooks/`，移除 `claude/commands/`
7. **安装后的目录策略** — 重写为 symlink 模型说明

### Task 2: 更新 CHANGELOG.md

在 `## 0.2.0` 上方插入 `## 0.3.0` 条目，10 个子条目覆盖全部 Phase 04 交付物：插件化安装、manifest 文件、hooks、废弃旧入口、安装模型变更、marketplace 修正、脚本重写、文档更新。

## Deviations from Plan

### Acceptance Criteria Divergence

**1. `claude/commands` 计数为 1（非 0）**
- **来源:** Task 1 acceptance criteria 要求 `grep -c 'claude/commands' README.md` 输出 0
- **原因:** `-CleanLegacy` 迁移说明中必须引用 `~/.claude/commands/liam-git-workflow/` 以告知用户旧安装产物的清理目标。该引用仅出现在迁移上下文中，不作为当前安装模型描述。
- **处置:** 接受此偏差。该引用是迁移功能正确性所必需的。

**2. `文件复制` 计数为 2（非 0）**
- **来源:** Task 1 acceptance criteria 要求 `grep -c '文件复制\|Copy-Item\|Copy-DirectoryTree' README.md` 输出 0
- **原因:** `-CleanLegacy` 迁移说明中使用 "文件复制模型" 描述旧版本安装方式，使用 "旧 Codex 文件复制" 描述清理目标。两者均仅出现在迁移上下文中。
- **处置:** 接受此偏差。这些引用帮助用户理解新旧模型差异，属于迁移文档的正确内容。

All other acceptance criteria fully met.

### Auto-fixed Issues

None — plan executed exactly as written for the main content.

## Threat Flags

None — README.md and CHANGELOG.md contain no sensitive information, no new network endpoints, no new auth paths, and no schema changes at trust boundaries. Threat model dispositions (T-04-17 accept, T-04-18 accept) remain accurate.

## Known Stubs

None — all README referenced features (plugin install, symlink install, CleanLegacy) correspond to implemented deliverables from Phase 04 Plans 01-03.

## Self-Check

- [x] README.md exists and contains `/plugin install` (verified: count=2)
- [x] README.md contains `CleanLegacy` (verified: count=2)
- [x] README.md no longer contains `/liam-git-workflow:` (verified: count=0)
- [x] README.md contains `.claude-plugin/` (verified: count=3)
- [x] CHANGELOG.md contains `## 0.3.0` (verified: count=1)
- [x] CHANGELOG.md 0.3.0 before 0.2.0 (verified: line 3 < line 16)
- [x] CHANGELOG.md 0.2.0 entry preserved intact (verified: 5 sub-entries present)
- [x] Commit `5ca618b` exists (verified: git log)
- [x] Commit `46c0e7b` exists (verified: git log)
- [x] No STATE.md modifications made
- [x] No ROADMAP.md modifications made
