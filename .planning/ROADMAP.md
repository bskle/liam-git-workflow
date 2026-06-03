# Roadmap: Liam Git Workflow — Remote Diagnostics

## Milestones

- [x] **v1.0 Remote Diagnostics** — Phases 1-3 (shipped 2026-05-25)

## Phases

<details>
<summary>[x] v1.0 Remote Diagnostics (Phases 1-3) — SHIPPED 2026-05-25</summary>

- [x] Phase 1: Diagnostic Foundation (1/1 plan) — completed 2026-05-25
- [x] Phase 2: Diagnostic Core (1/1 plan) — completed 2026-05-25
- [x] Phase 3: Integration (1/1 plan) — completed 2026-05-25

</details>

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Diagnostic Foundation | 1/1 | Complete | 2026-05-25 |
| 2. Diagnostic Core | 1/1 | Complete | 2026-05-25 |
| 3. Integration | 1/1 | Complete | 2026-05-25 |

### Phase 4: 插件化安装 - 让仓库能像 superpowers 一样在 Codex 和 Claude Code 中作为插件安装

**Goal:** 仓库能通过标准机制作为插件被 Codex 和 Claude Code 识别和安装 — Claude Code 侧支持 `/plugin install` 标准路径，Codex 侧支持市场安装与 symlink 备选方案，仓库结构对标 superpowers 自包含
**Requirements:** None (self-contained plugin packaging)
**Depends on:** Phase 3
**Plans:** 4 plans

Plans:
- [x] 04-01-PLAN.md — Claude Code 插件基础设施 (plugin.json + hooks.json + 废弃 claude/commands/)
- [x] 04-02-PLAN.md — Codex 插件配置精化 (版本升级 + marketplace 路径修正 + VERSION)
- [x] 04-03-PLAN.md — 安装脚本重写 (symlink 模型 install.ps1 + common.ps1 简化 + 兼容脚本更新)
- [x] 04-04-PLAN.md — 文档更新 (README 安装/使用/结构章节 + CHANGELOG v0.3.0)

### Phase 5: 元技能引导 — 自动发现与路由 ✓ (completed 2026-05-30)

**Goal:** Agent 通过 bootstrap 元技能能自动感知所有 Git 工作流技能的存在，通过 1% 规则优先使用技能而非手动执行 Git 命令
**Requirements:** None (self-contained meta-skill addition)
**Depends on:** Phase 4
**Plans:** 1 plan

Plans:
- [x] 05-01-PLAN.md — Bootstrap 元技能创建 (SKILL.md) + hooks.json SessionStart 更新
