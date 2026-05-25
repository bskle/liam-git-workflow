# Roadmap: Liam Git Workflow — Remote Diagnostics

## Overview

为 Liam Git Workflow 新增 Git 远程诊断能力：当 Agent 执行远程操作（push/pull/fetch/ls-remote）失败时，自动触发五层诊断流程，产出结构化结论供主 Agent 直接执行修复。三个阶段依次递进：先定义能力边界，再实现核心脚本，最后集成到现有工作流。

## Phases

- [ ] **Phase 1: Diagnostic Foundation** — 定义诊断技能的触发条件、诊断顺序、输出契约、交互边界和知识库 (1 plan)
- [ ] **Phase 2: Diagnostic Core** — 实现诊断脚本，覆盖五层诊断，产出结构化结论，最小化人工交互
- [ ] **Phase 3: Integration** — 将诊断能力接入现有工作流技能、场景文档和同步命令

## Phase Details

### Phase 1: Diagnostic Foundation
**Goal**: 诊断能力被完整定义，Agent 和用户均有明确入口访问
**Depends on**: Nothing (first phase)
**Requirements**: DIAG-01, DIAG-02, DIAG-03
**Success Criteria** (what must be TRUE):
  1. Agent 可以访问诊断技能定义（SKILL.md），其中明确指定触发条件、五层诊断顺序、输出契约、自动/人工交互边界
  2. 用户可以通过命令入口（claude/commands/）手动调用远程诊断，作为自动触发失败时的回退路径
  3. Agent 可以访问参考知识库（remote-diagnostics.md），其中包含故障分类、信号到原因映射、标准修复动作、升级与人工交互边界
**Plans:** 1 plan
- [x] 01-01-PLAN.md — 创建三个文档资产：技能定义（DIAG-01）、命令入口（DIAG-02）、参考知识库（DIAG-03）

### Phase 2: Diagnostic Core
**Goal**: 诊断脚本产出可操作的结构化结果，覆盖全部五层诊断，仅在下限 CLI 可观测范围时询问人工
**Depends on**: Phase 1
**Requirements**: DIAG-04, DIAG-08, DIAG-09, DIAG-10
**Success Criteria** (what must be TRUE):
  1. 对存在远程问题的仓库运行诊断脚本，输出结构化结论（包含问题分类、证据、可能原因、置信度、已执行动作、建议下一步、是否需要人工交互）
  2. 诊断系统性地覆盖五层：本地仓库状态 → 远程目标验证 → 认证/授权 → 网络路径 → 仓库策略
  3. 仅在 CLI 不可观测的信息时请求人工交互（浏览器状态、GitHub 权限页、VPN、代理客户端、系统证书）
**Plans:** 1 plan
- [x] 02-01-PLAN.md — 实现 scripts/diagnose_git_remote.ps1 诊断核心脚本：五层诊断（本地/远程/认证/网络/策略）+ 15+ 条信号到原因映射 + 结构化 JSON 输出（8 字段契约）

### Phase 3: Integration
**Goal**: 现有工作流技能在远程操作失败时自动触发或引用诊断能力
**Depends on**: Phase 2
**Requirements**: DIAG-05, DIAG-06, DIAG-07
**Success Criteria** (what must be TRUE):
  1. 当远程 Git 操作（push/pull/fetch/ls-remote）失败时，主工作流技能（liam-git-workflow）将请求路由到诊断能力
  2. 场景文档（scenarios.md）包含 push、pull、fetch、ls-remote 各至少一个远程故障场景示例
  3. 同步相关命令文档（sync-branch）引用远程诊断能力
**Plans:** 1 plan
- [ ] 03-01-PLAN.md — 三文件集成：主技能路由规则更新、场景文档补充、同步技能故障排除引用

## Progress

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Diagnostic Foundation | 1/1 | Done | 2026-05-25 |
| 2. Diagnostic Core | 0/1 | Planned | - |
| 3. Integration | 0/1 | Planned | - |
