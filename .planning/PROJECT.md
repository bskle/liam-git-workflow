# Liam Git Workflow

## What This Is

面向 Codex 和 Claude Code 的个人 Git 工作流插件包。把 Git 分支管理、提交规范、同步策略等日常操作收敛到统一入口，通过技能路由和自然语言交互完成 Git 工作，避免依赖零散记忆或临时 prompt。

## Core Value

**让 Agent 能自主完成完整的 Git 工作流** — 从分支创建、提交、同步到远程诊断，无需人工逐条记忆规则。

## Requirements

### Validated

- ✓ 分支类型选择与创建 — `liam-git-workflow-create-branch`
- ✓ 中文 Conventional Commit 草拟 — `liam-git-workflow-commit`
- ✓ 提交信息校验（格式/语言） — `validate_commit_message.ps1` + `commit-msg` hook
- ✓ 分支同步到 dev/main — `liam-git-workflow-sync-branch`
- ✓ 分支收尾与下一步指引 — `liam-git-workflow-finish`
- ✓ Hotfix 流程 — `liam-git-workflow-hotfix`
- ✓ Release 流程 — `liam-git-workflow-release`
- ✓ 本机 Git 配置审计 — `liam-git-workflow-sync-policy`
- ✓ Codex / Claude Code 双运行时安装与更新 — `install.ps1` / `update.ps1`
- ✓ Git 远程操作失败自动触发诊断 — `liam-git-workflow-remote-diagnose` — Validated in Phase 03
- ✓ 五层诊断覆盖（本地/远程/认证/网络/策略） — `diagnose_git_remote.ps1` + `remote-diagnostics.md` — Validated in Phase 02
- ✓ 双入口（自动触发 + 手动命令）共享同一诊断核心 — Validated in Phase 03
- ✓ 结构化诊断输出（8-field JSON contract） — Validated in Phase 02
- ✓ 人力交互最小化标准化 — 仅在下限 CLI 不可观测时询问 — Validated in Phase 02
- ✓ Claude Code 插件化安装 — `.claude-plugin/plugin.json` + `/plugin install` + SessionStart 钩子 — Validated in Phase 04
- ✓ Codex 插件配置精化 — `.codex-plugin/plugin.json` v0.3.0 + marketplace.json source.path 修正 — Validated in Phase 04
- ✓ Symlink 安装模型 — `install.ps1` 重写 (mklink /J) + common.ps1 简化 + 旧版迁移 — Validated in Phase 04
- ✓ 插件化文档更新 — README.md 安装/使用章节 + CHANGELOG.md v0.3.0 — Validated in Phase 04

### Active

*(All requirements validated — see Validated section)*

### Out of Scope

- 官方 marketplace 上架 — 当前仅面向个人本地使用
- 自动执行高风险 Git 命令 — 危险操作始终要求人工确认
- Cursor / Copilot / Gemini / OpenCode 适配 — 当前仅 Codex 和 Claude Code
- 远端版本检测与升级提醒 — 后续迭代考虑

## Context

- 项目运行在 Windows 11 + PowerShell 环境
- 设计文档位于 `docs/superpowers/specs/`，作为各功能的规格基线
- 现有 9 个技能（skills/）、8 个命令入口（claude/commands/）、参考文档（references/）
- 测试使用 Pester（PowerShell 测试框架），位于 `tests/`
- Git 提交规范遵循 ~/.claude/CLAUDE.md 第 2 章（Conventional Commits + 中文 subject）
- 当前分支 `feature/workflow-git-push-network-skill` 已完成所有 3 个 Phase 实现

## Constraints

- **运行时**: Windows 11, PowerShell 5.1+, Git 2.40+
- **语言**: 提交信息必须中文，代码注释和文档使用中文
- **安全**: 危险 Git 操作（force push, hard reset）需人工确认
- **环境**: 依赖 Codex/Claude Code 的技能/命令系统，不引入额外运行时依赖

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| 双入口设计（自动触发 + 手动命令） | 设计文档第 3 章：避免分裂诊断逻辑，两种入口共享同一核心 | Implemented — Phase 03 |
| 五层诊断顺序（本地→远程→认证→网络→策略） | 减少误判，先排除本地问题再分析网络 | Implemented — Phase 02 |
| 结构化输出契约 | 主 Agent 需要可操作的结论而非自由文本 | Implemented — Phase 02 |
| Symlink 替代文件复制 | Codex bug #17344: 文件级 symlink 被跳过，需使用目录 junction (mklink /J) | Implemented — Phase 04 |
| 插件化替代 slash commands | Claude Code `/plugin install` + skills 自动发现替代 `/command` 路由；废弃 claude/commands/ | Implemented — Phase 04 |
| 尽力而为部署策略 | SessionStart hooks (受 bug #16538 限制，配置语法正确，修复后立即可用) | Implemented — Phase 04 |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-26 after Phase 04 completion*
