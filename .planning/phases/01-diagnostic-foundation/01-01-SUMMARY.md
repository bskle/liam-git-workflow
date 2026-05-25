---
phase: 01-diagnostic-foundation
plan: 01
subsystem: diagnostics
tags: [git, remote, diagnostics, skill, command, reference]

# Dependency graph
requires: []
provides:
  - "技能定义文件：五层诊断触发条件、诊断顺序、8 字段结构化输出契约、人工交互规则"
  - "手动命令入口：$ARGUMENTS 用户输入、SKILL.md 和 remote-diagnostics.md 路由加载、五层工作流"
  - "参考知识库：10 类故障分类、5 层诊断清单（含具体检查命令）、15 条信号到原因映射、按层分类的修复动作、升级与人工交互边界、输出契约字段定义"
affects: [02-core-scripts, 03-workflow-integration]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "YAML frontmatter 技能定义模式（name + description + Markdown body）"
    - "双入口共享核心架构（自动触发 + 手动命令入口）"
    - "结构化输出契约模式（8 字段：problem_category / evidence / likely_cause / confidence / actions_taken / recommended_next_action / human_interaction_required / human_action_detail）"
    - "相对路径引用链：command → SKILL.md → remote-diagnostics.md"
    - "文档使用中文、代码/命令/标识符使用英文的混合规范"

key-files:
  created:
    - "skills/liam-git-workflow-remote-diagnose/SKILL.md"
    - "claude/commands/liam-git-workflow-remote-diagnose.md"
    - "references/remote-diagnostics.md"
  modified: []

key-decisions:
  - "遵循现有 liam-git-workflow 技能的 YAML frontmatter 和 Markdown 区块格局（Load First / Routing Rules / Response Style）"
  - "参照设计文档 §7 五层诊断顺序（本地→远程→认证→网络→策略），在命令入口和技能定义中保持一致"
  - "人工交互规则按三段式提示模板（为何不自动、用户做什么、回报什么），确保可操作性"
  - "参考知识库覆盖 15 条信号到原因映射，涵盖所有五层诊断的典型故障场景"

patterns-established:
  - "SKILL.md 模式：frontmatter → H1 → Load First → Trigger Conditions → Diagnostics Order → Output Contract → Human Interaction Rules → Response Style"
  - "Command .md 模式：frontmatter → 身份声明 → Read 区块 → $ARGUMENTS → Workflow → When to Use → Output → Response Rules"
  - "Reference .md 模式：中文 H1 → 故障分类表 → 诊断清单 → 信号映射 → 修复动作 → 升级边界 → 输出契约定义"

requirements-completed: [DIAG-01, DIAG-02, DIAG-03]

# Metrics
duration: 6min
completed: 2026-05-25
---

# Phase 01 Plan 01: Git 远程诊断文档资产总结

**创建 Git 远程诊断能力的三份规格文档：技能定义、命令入口和参考知识库，建立五层系统化诊断的文档化契约基础**

## Performance

- **Duration:** 6 分钟
- **Started:** 2026-05-25T02:15:03Z
- **Completed:** 2026-05-25T02:21:00Z
- **Tasks:** 3
- **Files created:** 3

## Accomplishments
- 创建了 `liam-git-workflow-remote-diagnose` 技能定义，包含自动/手动双重触发条件、严格排序的五层诊断流程、8 字段结构化输出契约、最小化的人工交互规则
- 创建了手动命令入口文件，复用现有命令模式的 YAML frontmatter + `$ARGUMENTS` + Read 区块格局，实现自动触发失败时的回退路径
- 创建了中文参考知识库，涵盖 10 类故障分类、15 条信号到原因映射、按诊断层分类的标准修复动作、6 种不可 CLI 观测场景及精确人工交互提示模板
- 三个文件之间通过相对路径引用形成完整的知识链：命令 → SKILL.md → remote-diagnostics.md

## Task Commits

Each task was committed atomically:

1. **Task 1: 创建远程诊断技能定义文件 (DIAG-01)** - `98c5685` (feat)
2. **Task 2: 创建手动命令入口文件 (DIAG-02)** - `c60c641` (feat)
3. **Task 3: 创建远程诊断参考知识库文件 (DIAG-03)** - `0a30edf` (docs)

## Files Created

- `skills/liam-git-workflow-remote-diagnose/SKILL.md` — 技能定义文件，定义触发条件、五层诊断顺序、输出契约、人工交互规则、响应风格（144 行）
- `claude/commands/liam-git-workflow-remote-diagnose.md` — 命令入口文件，提供 `$ARGUMENTS` 用户输入、五层诊断工作流、结构化输出格式、响应规则（55 行）
- `references/remote-diagnostics.md` — 参考知识库，包含故障分类表、五层诊断清单（含具体命令）、15 条信号到原因映射、按层修复动作、升级边界、输出契约字段定义（202 行）

## Decisions Made

所有实现严格遵循设计文档和现有模式文件的结构约定，未做额外决策：YAML frontmatter 键名、Markdown 区块命名、相对路径引用格式、诊断层编号和顺序均与设计规格一致。

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- **Commit message hook 兼容性：** 在 Windows bash 环境下，使用 heredoc 传入中文多行提交消息时触发 PowerShell 格式校验失败。改用临时文件 (`-F`) 方式写入提交消息后正常通过校验。此为基础环境兼容性问题，非计划偏差。

## Next Phase Readiness

- 三份规格文档完整交付，Phase 2（核心脚本实现 `scripts/diagnose_git_remote.ps1`）可直接参照参考知识库中的诊断清单和命令列表进行实现
- 文档覆盖了设计规格中 Phase 1 的全部内容（§4.1、§4.2、§4.3），可作为后续实现的权威参考

---
*Phase: 01-diagnostic-foundation*
*Completed: 2026-05-25*
