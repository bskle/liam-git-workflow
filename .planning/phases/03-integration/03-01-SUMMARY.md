---
phase: 03-integration
plan: 01
subsystem: integration
tags: [routing, scenarios, troubleshooting, documentation]
requires: [liam-git-workflow-remote-diagnose, remote-diagnostics.md]
provides: [DIAG-05, DIAG-06, DIAG-07]
affects: [liam-git-workflow, liam-git-workflow-sync-branch, scenarios]
tech-stack:
  added: []
  patterns: [skill-routing, scenario-documentation, fault-classification-linking]
key-files:
  created: []
  modified:
    - skills/liam-git-workflow/SKILL.md
    - references/scenarios.md
    - skills/liam-git-workflow-sync-branch/SKILL.md
decisions:
  - 路由规则按触发来源归类：用户描述型（第 9 条）位于执行失败型（第 10 条）之前，区分主动请求和被动响应
  - 场景示例按诊断层排序（第 5 层 → 第 3 层 → 第 4 层 → 第 4 层），而非按命令字母顺序
metrics:
  duration: 0h 8m
  tasks: 3
  files: 3
  completed_date: "2026-05-25"
---

# Phase 3 Plan 1: Integration Summary

将 Phase 1 和 Phase 2 构建的远程诊断能力接入现有工作流系统，完成"自动触发 + 手动回退"双入口设计的最后一环。

## Tasks Completed

| # | Task | Commit | Files Modified |
|---|------|--------|----------------|
| 1 | 为主工作流技能添加远程故障路由规则 (DIAG-05) | `aefd02f` | `skills/liam-git-workflow/SKILL.md` |
| 2 | 为场景参考文档补充远程故障场景示例 (DIAG-06) | `984b477` | `references/scenarios.md` |
| 3 | 为同步分支技能添加远程诊断引用和故障排除 (DIAG-07) | `4720022` | `skills/liam-git-workflow-sync-branch/SKILL.md` |

## Changes Summary

### Task 1: liam-git-workflow SKILL.md (DIAG-05)

- **Load First 区块**: 新增 `../../references/remote-diagnostics.md` 引用，确保主工作流加载诊断知识库
- **Routing Rules 区块**: 新增两条远程故障路由规则：
  - 第 9 条 — 用户描述型：当用户描述 push/pull/fetch/ls-remote 返回已知错误模式时路由到诊断技能
  - 第 10 条 — 执行失败型：当远程 Git 操作以非零退出码失败时，停止当前操作并路由到诊断技能
- **Response Style 区块**: 新增远程故障响应指引 — 失败时不立即重试同一命令

### Task 2: references/scenarios.md (DIAG-06)

新增 4 个远程故障场景，覆盖四类 Git 远程命令：

| 场景 | 命令 | 故障类型 | 诊断层 |
|------|------|---------|--------|
| Push 失败：受保护分支 | push | 仓库策略拒绝 | 第 5 层 |
| Pull 失败：认证凭据过期 | pull | 认证失败 | 第 3 层 |
| Fetch 失败：DNS 解析 | fetch | DNS 解析失败 | 第 4 层 |
| ls-remote 失败：连接超时 | ls-remote | 连接超时/拒绝 | 第 4 层 |

每个场景包含完整的 Expected classification：problem category、trigger signal、route to（技能名）、reference（知识库引用）、suggested action（可执行操作）。

### Task 3: liam-git-workflow-sync-branch SKILL.md (DIAG-07)

- **Read first 区块**: 新增 `../../references/remote-diagnostics.md` 引用
- **Workflow 第 4 步**: 追加远程操作失败时停止并路由到诊断的指引
- **新增 Troubleshooting 章节**: 包含：
  - 三步骤故障处理流程（路由诊断 → 应用修复 → 重试）
  - 5 种常见同步期间远程故障及其诊断层编号（第 2-5 层）
  - 指向 `references/remote-diagnostics.md` 的完整知识库引用

## Verification Results

Phase 级别验证全部通过：

1. 三文件均引用 `liam-git-workflow-remote-diagnose`：3/3
2. 三文件均引用 `remote-diagnostics.md`：3/3
3. 主工作流 Routing Rules 从 8 条扩展到 10 条
4. scenarios.md 从 5 个场景扩展到 9 个场景
5. sync-branch SKILL.md 新增 Troubleshooting 章节

## Deviations from Plan

None — plan executed exactly as written.

## Known Stubs

None — all references point to existing, implemented artifacts.

## Threat Flags

None — documentation-only changes with no new attack surface.

## Self-Check

- [x] `skills/liam-git-workflow/SKILL.md` — modified, verified
- [x] `references/scenarios.md` — modified, verified
- [x] `skills/liam-git-workflow-sync-branch/SKILL.md` — modified, verified
- [x] Commit `aefd02f` — exists in git log
- [x] Commit `984b477` — exists in git log
- [x] Commit `4720022` — exists in git log
