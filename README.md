# Liam Git Workflow

面向 Codex 的个人 Git 工作流插件。

## 目标

把 Liam 的 Git 规则和常用操作收敛到一个统一入口里，避免平时还要靠零散的记忆、全局说明文件或临时 prompt 才能完成日常 Git 工作。

当前覆盖的能力包括：

- 选择合适的分支类型
- 从正确的基线创建分支
- 生成中文 Conventional Commit
- 将工作分支同步到 `dev` 或 `main`
- 完成分支收尾并准备下一步 Git 动作
- 处理线上 hotfix 流程
- 准备 release 流程
- 按策略审计本机 Git 配置

## 在 Codex 中使用

主入口：

```text
$liam-git-workflow
创建一个线上 bug 修复分支，修复 login 出现的网络问题
```

帮助入口：

```text
$liam-git-workflow-help
```

精确入口：

```text
$liam-git-workflow-create-branch
$liam-git-workflow-commit
$liam-git-workflow-sync-branch
$liam-git-workflow-finish
$liam-git-workflow-hotfix
$liam-git-workflow-release
$liam-git-workflow-sync-policy
```

## 使用约定

- 在 Codex 中优先使用 `$liam-git-workflow`
- 不依赖 `$Liam Git Workflow`
- 插件名统一使用小写加连字符，保证触发稳定

## 规则来源

- [policy.md](D:/liam/project/others/20260511_liam_git_workflow/references/policy.md): 核心工作流策略
- [branch-matrix.md](D:/liam/project/others/20260511_liam_git_workflow/references/branch-matrix.md): 分支决策规则
- [commit-rules.md](D:/liam/project/others/20260511_liam_git_workflow/references/commit-rules.md): 提交规范
- [pr-rules.md](D:/liam/project/others/20260511_liam_git_workflow/references/pr-rules.md): PR 与合并规则
- [scenarios.md](D:/liam/project/others/20260511_liam_git_workflow/references/scenarios.md): 常见场景示例

## 仓库结构

```text
.codex-plugin/
.agents/plugins/
skills/
references/
scripts/
```

## 安装说明

这个仓库被设计成一个本地 Codex 插件仓库。

插件清单位于：

- [plugin.json](D:/liam/project/others/20260511_liam_git_workflow/.codex-plugin/plugin.json)

本地 marketplace 入口位于：

- [marketplace.json](D:/liam/project/others/20260511_liam_git_workflow/.agents/plugins/marketplace.json)

## 同步到全局技能库

如果你希望在 Codex 全局技能库中直接使用这组技能，同时继续把当前仓库作为唯一维护源，可以运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\link_codex_global_skills.ps1
```

这个脚本会在 `C:\Users\250707012\.codex\skills\` 下为每个 `liam-git-workflow*` 技能目录创建 junction，并额外创建一个 `C:\Users\250707012\.codex\references` junction，确保原有相对引用路径仍然有效。

## 当前范围

第一版重点放在策略沉淀、路由规则和可复用提示上。当前还不包含那些会在未确认前自动执行高风险 Git 操作的命令包装器。
