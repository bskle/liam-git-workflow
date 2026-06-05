# Liam Git Workflow

面向 Claude Code 和 Codex 的个人 Git 工作流插件 — 分支管理、中文约定式提交、同步策略与远程诊断。

## 安装

### Claude Code

```bash
claude plugin marketplace add bskle/liam-git-workflow
claude plugin install liam-git-workflow@liam-git-workflow
```

### Codex

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -SkipClaude
```

## 更新

### Claude Code

```bash
claude plugin marketplace update liam-git-workflow
claude plugin update liam-git-workflow@liam-git-workflow
```

### Codex

```bash
git -C <仓库路径> pull --rebase
```

## 功能概览

**分支管理**
- **gw-create-branch** — 从正确基线创建规范命名分支
- **gw-finish** — 完成分支工作并准备下一步 Git 操作

**提交与同步**
- **gw-commit** — 生成中文约定式提交信息
- **gw-sync** — 将工作分支同步到 dev 或 main
- **gw-sync-policy** — 审计本地 Git 配置是否符合规范

**运维操作**
- **gw-hotfix** — 生产紧急修复工作流
- **gw-release** — 打标签并合并 dev 到 main
- **gw-diagnose** — 结构化远程操作故障诊断

**元功能**
- **gw** — 自然语言路由入口
- **gw-help** — 列出所有可用技能
- **gw-bootstrap** — 以斜杠命令形式发现技能

## 规则

所有 Git 规则定义在 `references/` 目录：

- [policy.md](references/policy.md) — 分支模型与合并层级
- [commit-rules.md](references/commit-rules.md) — 约定式提交格式（要求中文主题）
- [branch-matrix.md](references/branch-matrix.md) — 分支类型决策规则
- [pr-rules.md](references/pr-rules.md) — PR 要求与评审流程
- [scenarios.md](references/scenarios.md) — 常见工作流示例

## 提交钩子（可选）

在目标仓库中强制校验提交信息格式：

```powershell
powershell -ExecutionPolicy Bypass -File <安装路径>\scripts\install_repo_hooks.ps1 -RepoRoot .
```

## 许可证

MIT — 详见 [LICENSE](LICENSE)
