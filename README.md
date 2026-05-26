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

- **Claude Code**：通过 `.claude-plugin/plugin.json` 作为标准插件安装，skills 通过 Skill tool 自动可用
- **Codex**：通过 `.codex-plugin/plugin.json` 和市场注册或 symlink 脚本安装

不包含：

- 官方 marketplace 上架流程
- 自动执行高风险 Git 命令的命令包装器
- 面向 Cursor、Copilot、Gemini、OpenCode 的适配层

## 在 Codex 中使用

Codex 安装后，以下技能可通过 Skill tool 调用:

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
$liam-git-workflow-remote-diagnose
```

## 在 Claude Code 中使用

插件安装后，所有技能通过 Skill tool 自动可用。在会话中使用自然语言描述 Git 操作需求即可。

主要技能入口:
- `liam-git-workflow` — 默认路由入口
- `liam-git-workflow-help` — 查看所有可用技能
- `liam-git-workflow-create-branch` — 创建分支
- `liam-git-workflow-commit` — 生成中文 Conventional Commit
- `liam-git-workflow-sync-branch` — 同步分支
- `liam-git-workflow-finish` — 完成分支收尾
- `liam-git-workflow-hotfix` — 生产 hotfix 流程
- `liam-git-workflow-release` — 发布流程
- `liam-git-workflow-sync-policy` — 审计 Git 配置与策略对齐
- `liam-git-workflow-remote-diagnose` — 远程操作失败诊断

## 安装

### 前置条件

- Windows 11, PowerShell 5.1+, Git 2.40+
- Claude Code (如需 Claude Code 集成) 或 Codex (如需 Codex 集成)

### Claude Code 安装

**方式 1: /plugin install (推荐)**

在 Claude Code 会话中运行:
```text
/plugin install <仓库路径>
```

Claude Code 会自动发现 `.claude-plugin/plugin.json`，加载 skills/ 目录中的全部技能，并注册 hooks/ 中的钩子。

**方式 2: 启动参数**

```powershell
claude --plugin-dir <仓库路径>
```

安装后，skills/ 中的技能通过 Skill tool 自动可用。无需额外配置。

### Codex 安装

**方式 1: 运行安装脚本 (推荐)**

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -SkipClaude
```

脚本会在 `~/.agents/skills/liam-git-workflow` 创建指向 `skills/` 的目录符号链接 (directory junction)。Codex 启动时自动扫描该路径。

**方式 2: 添加市场源**

将仓库的 `.agents/plugins/marketplace.json` 添加到 Codex 的市场源列表中，然后在 Codex 插件界面安装 "liam-git-workflow"。

### 同时安装两个平台

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1
```

不加 `-SkipCodex` 或 `-SkipClaude` 标志时，脚本会同时配置 Codex (symlink) 和提示 Claude Code 安装命令。

### 从旧版本迁移

如果你之前使用过 0.2.0 或更早版本（文件复制模型），运行带清理标志的安装命令:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -CleanLegacy
```

`-CleanLegacy` 会清理以下旧安装产物:
- `~/.codex/skills/liam-git-workflow*` (旧 Codex 文件复制)
- `~/.claude/commands/liam-git-workflow/` (旧 Claude Code slash commands)
- 已失效的旧 directory junction

## 更新

symlink 安装模式下，更新仓库即更新插件:

```bash
cd <仓库路径>
git pull --rebase
```

无需重新运行安装脚本 — symlink 直接指向仓库文件，git pull 后立即生效。

如果你需要从 `main` 拉取最新版本后重新执行安装:

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
.claude-plugin/
.codex-plugin/
.agents/plugins/
skills/
hooks/
references/
scripts/
tests/
CHANGELOG.md
README.md
VERSION
```

## 安装后的目录策略

所有技能文件通过 symlink (Codex) 或插件目录注册 (Claude Code) 直接指向仓库中的 `skills/` 目录。skill 内部引用 (`../../references/`、`../../scripts/`) 使用仓库内相对路径，在两种安装模式下均正确解析。

这意味着:
- 无需复制文件到平台特定目录
- 无需在安装时重写 skill 内部路径
- `git pull` 后技能内容自动更新
- 同一仓库可同时服务于 Codex 和 Claude Code

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

