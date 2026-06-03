---
name: liam-git-workflow-bootstrap
description: Git 工作流技能自动发现与路由入口。列出全部可用技能、触发条件和路由规则。当 Agent 遇到涉及 Git 操作的用户请求时，优先查询此技能确认是否存在对应的专用技能，避免手动执行 Git 命令。
---

# Liam Git Workflow — 技能发现入口

## 1. 这是什么

本技能是 Git 工作流技能体系的元技能/gatekeeper，对标 superpowers 的 `using-superpowers` 角色。它是前置发现层，不替代 `liam-git-workflow` 主路由技能。Agent 通过本技能可自动发现全部 10 个 Git 工作流技能并路由到正确的子技能。

## 2. 1% 规则

只要用户请求涉及 Git 操作，Agent 有责任先检查是否有对应技能。即使只有 1% 的概率匹配，也必须先查询本技能清单。**禁止 Agent 在未检查技能的情况下直接执行 Git 命令。**

Git 操作信号包括：分支创建/切换、commit、push、pull、fetch、merge、rebase、tag、hotfix、release、remote error、config audit、工作流咨询等。

## 3. 技能清单

所有技能在 Claude Code 中作为斜杠命令直接可用，输入 `/` 即可触发命令补全列表，或直接输入完整命令名调用。

| 技能名称 | 斜杠命令 | 触发场景 | 典型请求示例 |
|---------|---------|---------|-------------|
| `liam-git-workflow` | `/liam-git-workflow` | 自然语言 Git 请求，不确定用哪个技能 | "帮我提交代码"、"我要发布" |
| `liam-git-workflow-help` | `/liam-git-workflow-help` | 询问可用命令列表或入口 | "有哪些 Git 命令可用"、"怎么用" |
| `liam-git-workflow-create-branch` | `/liam-git-workflow-create-branch` | 创建或命名分支 | "我要创建功能分支"、"新建 bugfix 分支" |
| `liam-git-workflow-commit` | `/liam-git-workflow-commit` | 提交变更 | "提交当前修改"、"帮我写提交信息" |
| `liam-git-workflow-sync-branch` | `/liam-git-workflow-sync-branch` | 同步最新基线 | "同步 dev 分支最新代码"、"rebase main" |
| `liam-git-workflow-finish` | `/liam-git-workflow-finish` | 完成分支收尾，询问下一步 | "分支做完了下一步是什么" |
| `liam-git-workflow-hotfix` | `/liam-git-workflow-hotfix` | 生产问题修复 | "线上有 bug 需要紧急修复" |
| `liam-git-workflow-release` | `/liam-git-workflow-release` | 打标签或合并 dev 到 main | "发布版本"、"打 tag"、"合并到 main" |
| `liam-git-workflow-sync-policy` | `/liam-git-workflow-sync-policy` | 审计 Git 配置与策略 | "检查我的 Git 配置是否符合规范" |
| `liam-git-workflow-remote-diagnose` | `/liam-git-workflow-remote-diagnose` | 远程操作失败诊断 | "push 失败了"、"认证错误"、"connection timed out" |

触发场景描述与 `liam-git-workflow` 主路由的 Routing Rules 保持一致，避免两套路由逻辑分歧。

## 4. 路由优先级

路由链：**bootstrap (本技能) $\to$ liam-git-workflow (主路由) $\to$ 具体子技能**

- 用户意图模糊 → route to `liam-git-workflow`（主路由自动判断）
- 用户意图明确且匹配某个子技能 → 可直接 route to 具体子技能
- 用户询问有哪些技能可用 → route to `liam-git-workflow-help`
- **任何 Git 操作前** → 先检查本技能清单

当 bootstrap 不确定路由到哪个子技能时，应让 `liam-git-workflow` 主路由处理。Bootstrap 不替代主路由。

## 5. Red Flags — Agent 禁止的借口

| Agent 可能说的借口 | 为什么这是错误的 | 正确做法 |
|------------------|-----------------|---------|
| "这是一个简单的 git commit，不需要技能" | 技能确保提交信息格式正确（中文 + Conventional Commits），手动操作容易出错 | 使用 `liam-git-workflow-commit` |
| "用户只是想查看分支，不需要技能" | 技能清单中的技能覆盖完整 Git 工作流 | 检查清单确认场景 |
| "我先执行 git push 看看" | remote-diagnose 技能在 push 失败时提供结构化诊断，盲目重试浪费时间 | 使用 `liam-git-workflow-remote-diagnose` |
| "我知道这些命令，不需要帮助" | 技能不仅执行命令，还确保策略合规（分支模型、提交规范） | 始终通过技能路由 |
| "这看起来不需要 bootstrap" | bootstrap 是元技能入口，它的存在就是为了被查询 | 遇到 Git 操作先查 bootstrap |

## 6. 使用示例

**示例 1: 提交代码**
- 用户说: "提交当前修改"
- Agent 看到 Git 操作信号 → 检查 bootstrap 技能清单 → 匹配 `liam-git-workflow-commit`
- 调用 `liam-git-workflow-commit` 技能
- 斜杠方式: 直接输入 `/liam-git-workflow-commit` 调用提交技能

**示例 2: 不确定操作类型**
- 用户说: "我要发布一个新版本"
- Agent 不确定是 release 还是普通 tag → route to `liam-git-workflow` 主路由
- 主路由判断: 合并 dev$\to$main + tag → 调用 `liam-git-workflow-release`
- 斜杠方式: 直接输入 `/liam-git-workflow-release` 调用发布技能

**示例 3: push 失败**
- Agent 执行 git push 返回认证错误
- Agent 不重试 → 检查 bootstrap 清单 → 匹配 `liam-git-workflow-remote-diagnose`
- 调用诊断技能进行结构化故障排查
- 斜杠方式: 直接输入 `/liam-git-workflow-remote-diagnose` 调用诊断技能

**示例 4: 询问可用技能**
- 用户说: "Git 工作流有哪些功能"
- Agent → route to `liam-git-workflow-help`
- Help 技能列出所有入口和用法
- 斜杠方式: 输入 `/` 浏览命令补全列表，或直接输入 `/liam-git-workflow-bootstrap` 查看完整技能清单

## 7. 与 liam-git-workflow 主路由的关系

Bootstrap 是发现层（在 Agent 不知道该用什么技能时被查询），`liam-git-workflow` 是路由层（在用户意图不明确时自动判断路由到哪个子技能）。两者互补：Bootstrap 确保 agent 知道技能存在，主路由确保路由到正确的技能。
