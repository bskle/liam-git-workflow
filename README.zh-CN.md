# Liam Git Workflow

面向 Codex 的个人 Git 工作流插件。

## 目标

把 Liam 的 Git 规则底座统一收敛到一个可调用插件里，避免再靠全局 `CLAUDE.md`、零散 skill 和记忆入口名来完成日常 Git 操作。

这个插件覆盖：

- 创建正确类型的分支
- 生成中文 Conventional Commit
- 同步当前分支到正确基线
- 完成分支收尾和 PR 准备
- 处理线上 hotfix
- 处理 release 流程
- 检查本机 Git 全局配置是否符合策略

## 在 Codex 中使用

主入口：

```text
$liam-git-workflow
创建一个线上bug修复的分支，修复login出现的网络问题
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

- 在 Codex 中，推荐使用 `$liam-git-workflow`
- 不建议依赖 `$Liam Git Workflow`
- 主入口支持自然语言路由
- 子入口适合你想精准控制动作时使用

## 规则来源

- [policy.md](D:/liam/project/others/20260511_liam_git_workflow/references/policy.md)
- [branch-matrix.md](D:/liam/project/others/20260511_liam_git_workflow/references/branch-matrix.md)
- [commit-rules.md](D:/liam/project/others/20260511_liam_git_workflow/references/commit-rules.md)
- [pr-rules.md](D:/liam/project/others/20260511_liam_git_workflow/references/pr-rules.md)
- [scenarios.md](D:/liam/project/others/20260511_liam_git_workflow/references/scenarios.md)

## 当前状态

第一版已经完成：

- plugin manifest
- 本地 marketplace 入口
- 完整 skill 骨架
- 规则参考文档
- Git 全局配置审计脚本

当前还没有做：

- 无确认自动执行高风险 Git 操作
- 更强的命令包装脚本
- forward-testing 和触发调优

