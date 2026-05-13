# Liam Git Workflow

面向 Codex 和 Claude Code 的个人 Git 工作流插件包。

## 目标

把 Liam 的 Git 规则和常用操作收敛到一个统一入口里，避免平时还要靠零散记忆、全局说明文件或临时 prompt 才能完成日常 Git 工作。

当前覆盖的能力包括：

- 选择合适的分支类型
- 从正确的基线创建分支
- 生成中文 Conventional Commit
- 将工作分支同步到 `dev` 或 `main`
- 完成分支收尾并准备下一步 Git 动作
- 处理线上 hotfix 流程
- 准备 release 流程
- 按策略审计本机 Git 配置

## 运行时支持

当前版本支持两个生态：

- Codex：通过本地插件元数据和全局 skills 安装
- Claude Code：通过自定义 slash commands 安装

不包含：

- 官方 marketplace 上架流程
- 自动执行高风险 Git 命令的命令包装器
- 面向 Cursor、Copilot、Gemini、OpenCode 的适配层

## 在 Codex 中使用

```text
$liam-git-workflow 创建一个线上 bug 修复分支，修复 login 出现的网络问题 
$liam-git-workflow-help
$liam-git-workflow-create-branch
$liam-git-workflow-commit
$liam-git-workflow-sync-branch
$liam-git-workflow-finish
$liam-git-workflow-hotfix
$liam-git-workflow-release
$liam-git-workflow-sync-policy
```

## 在 Claude Code 中使用

```text
/liam-git-workflow 创建一个线上 bug 修复分支，修复 login 出现的网络问题
/liam-git-workflow-help
/liam-git-workflow-create-branch
/liam-git-workflow-commit
/liam-git-workflow-sync-branch
/liam-git-workflow-finish
/liam-git-workflow-hotfix
/liam-git-workflow-release
/liam-git-workflow-sync-policy
```

## 安装

### 同时安装 Codex 和 Claude Code

在仓库根目录运行：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

默认行为：

- 将 Codex skills 安装到 `$env:CODEX_HOME\skills\` 或 `C:\Users\<you>\.codex\skills\`
- 将 Claude 命令安装到 `C:\Users\<you>\.claude\commands\liam-git-workflow\`
- 在 `C:\Users\<you>\.liam-git-workflow\install.json` 写入安装元数据

### 只安装 Codex

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -SkipClaude
```

### 只安装 Claude Code

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -SkipCodex
```

## 更新

使用当前仓库内容重新同步安装产物：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\update.ps1
```

如果你希望脚本先从远端拉取最新版本，再执行同步：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\update.ps1 -PullLatest
```

`-PullLatest` 会在仓库存在本地未提交修改时拒绝执行，避免误覆盖工作区。

## 提交校验

这一版增加了仓库级 `commit-msg` 校验，用来拒绝不符合规则的提交信息。校验规则包括：

- 格式必须为 `<type>(<scope>): <subject>`
- `type` 必须在 Conventional Commit 白名单中
- `scope` 必须是紧凑英文短词
- `subject` 必须包含中文字符

在目标仓库根目录启用 hook：

```powershell
powershell -ExecutionPolicy Bypass -File <liam-git-workflow-install-path>\scripts\install_repo_hooks.ps1 -RepoRoot .
```

这个脚本会把内置的 hook 模板和校验脚本物化到目标仓库的 `.githooks/`，然后设置：

```text
core.hooksPath = .githooks
```

手动校验一个提交信息文件：

```powershell
powershell -ExecutionPolicy Bypass -File .\.githooks\validate_commit_message.ps1 -CommitMessageFile .git\COMMIT_EDITMSG
```

## 目录结构

```text
.agents/plugins/
.codex-plugin/
claude/commands/
references/
scripts/
skills/
tests/
CHANGELOG.md
VERSION
```

## 安装后的目录策略

为了避免覆盖用户已有的全局 `references` 目录，Codex 安装器不会再接管整个 `$CODEX_HOME\references`。当前策略是：

- skills 安装到 `$CODEX_HOME\skills\liam-git-workflow*`
- 共享支持文件安装到 `$CODEX_HOME\skills\liam-git-workflow-support\`
- 安装时自动重写 skill 内部引用路径，让它们指向 support 目录

Claude Code 安装器会把命令、参考资料和辅助脚本都放到：

- `~/.claude/commands/liam-git-workflow/`

这样安装产物是自包含的，更新时只需要重新运行安装器。

## 兼容脚本

历史脚本仍然保留：

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\link_codex_global_skills.ps1
```

它现在会转调 `install.ps1 -SkipClaude`，用于兼容旧的 Codex-only 使用习惯。

## 规则来源

- [policy.md](D:/liam/project/others/20260511_liam_git_workflow/references/policy.md): 核心工作流策略
- [branch-matrix.md](D:/liam/project/others/20260511_liam_git_workflow/references/branch-matrix.md): 分支决策规则
- [commit-rules.md](D:/liam/project/others/20260511_liam_git_workflow/references/commit-rules.md): 提交规范
- [pr-rules.md](D:/liam/project/others/20260511_liam_git_workflow/references/pr-rules.md): PR 与合并规则
- [scenarios.md](D:/liam/project/others/20260511_liam_git_workflow/references/scenarios.md): 常见场景示例

## 当前范围

这一版重点放在：

- Git 规则沉淀
- Codex / Claude 双运行时入口
- 本地安装与更新流程
- 可重复分发的目录结构

这一版还不包含：

- 官方 marketplace 发布
- 自动执行危险 Git 动作
- 远端版本检测和升级提醒

