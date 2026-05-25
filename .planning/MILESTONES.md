# Milestones

## v1.0 Remote Diagnostics (Shipped: 2026-05-25)

**Phases completed:** 3 phases, 3 plans, 7 tasks

**Key accomplishments:**

1. 创建三份诊断文档资产，建立五层系统化诊断的文档化契约基础 — 技能定义、双入口命令、15 条信号到原因映射知识库
2. 实现 400+ 行 PowerShell 诊断核心脚本，覆盖五层诊断（本地→远程→认证→网络→策略），21 条声明式信号映射，8 字段结构化 JSON 输出契约
3. 完成工作流集成闭环 — 主技能新增用户描述型和执行失败型两条路由规则，场景文档补充 4 个远程故障场景（push/pull/fetch/ls-remote），同步分支技能新增 Troubleshooting 章节和远程诊断引用

**Requirements:** 10/10 validated (DIAG-01 through DIAG-10)

**Delivered:** 当 Agent 执行远程 Git 操作失败时，自动触发五层诊断流程，产出结构化结论供主 Agent 直接执行修复。

---
