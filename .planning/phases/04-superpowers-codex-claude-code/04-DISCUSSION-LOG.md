# Phase 4: 插件化安装 - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-25
**Phase:** 04-superpowers-codex-claude-code
**Areas discussed:** 跨平台一致性

---

## 跨平台一致性

### Skills vs Commands（Claude Code 技能格式统一）

| Option | Description | Selected |
|--------|-------------|----------|
| 统一到 skills | skills/ 作为唯一技能定义，Claude Code 自动发现，废弃 claude/commands/ | ✓ |
| Skills 为主 + commands 做入口 | skills/ 是核心，保留少量 commands 作为快捷入口 | |
| 保留现状 | skills/ 给 Codex，claude/commands/ 给 Claude Code | |

**User's choice:** 统一到 skills（推荐）
**Notes:** 减少双轨维护成本。用户仍可通过 Skill 工具或 /skill-name 调用。

### 安装方式（Claude Code）

| Option | Description | Selected |
|--------|-------------|----------|
| 符号链接 | git clone 后创建 symlink，更新只需 git pull | |
| /plugin install 机制 | 添加 .claude-plugin/plugin.json，通过 /plugin install 安装 | ✓ |
| 两者都支持 | symlink + /plugin install | |

**User's choice:** /plugin install 机制
**Notes:** 使用 Claude Code 标准插件安装路径。

### 安装方式（Codex）

| Option | Description | Selected |
|--------|-------------|----------|
| Codex 市场安装 | 已有 .codex-plugin/plugin.json + marketplace.json | |
| 符号链接脚本 | 简化版 install.ps1 只做 symlink | |
| 两者都支持 | 市场安装 + symlink 脚本 | ✓ |

**User's choice:** 两者都支持

### 文件组织

**User's choice:** 对标 superpowers，仓库自身布局即为插件包结构。skills 内用相对路径引用 support 文件。

---

## Claude's Discretion

- `.claude-plugin/plugin.json` 的具体字段值（版本号、描述文案）
- 废弃 `claude/commands/` 时的清理策略（直接删除 vs 迁移过渡期）
- symlink 脚本的具体实现细节

## Deferred Ideas

- 官方 marketplace 上架 — Out of scope
- Cursor / Copilot / Gemini / OpenCode 适配 — Out of scope
- 远端版本检测与升级提醒 — 后续迭代
