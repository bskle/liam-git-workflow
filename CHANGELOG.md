# Changelog

## 0.3.0

- 插件化安装: 仓库支持 Claude Code `/plugin install` 标准安装路径
- 新增 `.claude-plugin/plugin.json` — Claude Code 插件注册 manifest
- 新增 `hooks/hooks.json` — SessionStart 会话钩子 (已知限制: Claude Code bug #16538 导致 SessionStart additionalContext 不会注入到 agent 上下文)
- 废弃 `claude/commands/` — 删除 10 个旧 slash commands; Claude Code 侧统一通过 skills 机制加载
- 安装模型从文件复制改为目录符号链接 (Codex `mklink /J` + Claude Code plugin-dir 注册)
- 修正 Codex `marketplace.json` source.path 从 "." 修正为 "../.." (确保 Codex 正确发现 repo root 中的 plugin.json)
- 简化 `scripts/common.ps1` — 移除文件复制和路径重写函数, 更新元数据格式
- 重写 `scripts/install.ps1` — symlink 模型, 支持 `-CleanLegacy` 清理旧安装产物
- 更新 `scripts/link_codex_global_skills.ps1` 和 `scripts/update.ps1` 兼容新安装模型
- 更新 README.md 安装/使用/更新/目录章节反映插件化架构

## 0.2.0

- add unified Codex and Claude installation script
- add local update script with optional `git pull --rebase`
- add Claude Code custom command templates
- package Codex support assets without taking over global `references`
- document cross-runtime installation and update flow
