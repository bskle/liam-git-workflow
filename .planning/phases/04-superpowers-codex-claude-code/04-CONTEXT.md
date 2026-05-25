# Phase 4: 插件化安装 - Context

**Gathered:** 2026-05-25
**Status:** Ready for planning

<domain>
## Phase Boundary

让仓库能像 superpowers 一样作为插件被 Codex 和 Claude Code 识别和安装。
核心交付：仓库自包含的插件化结构，用户 clone 后即可通过标准机制安装，不再依赖 `install.ps1` 的手动文件复制逻辑。

**In scope:**
- Claude Code 侧 `.claude-plugin/plugin.json` 支持 `/plugin install`
- 统一 `skills/*/SKILL.md` 作为唯一定义，废弃 `claude/commands/`
- Codex 市场安装 + symlink 脚本双通道
- 目录结构对标 superpowers，仓库自包含

**Out of scope:**
- 官方 marketplace 上架发布
- Cursor / Copilot / Gemini / OpenCode 适配
- 远端版本检测和自动升级
</domain>

<decisions>
## Implementation Decisions

### 技能统一与格式
- **D-01:** `skills/` 作为唯一技能定义源，每个技能一个子目录，内含 `SKILL.md`
- **D-02:** 废弃 `claude/commands/` 目录，Claude Code 侧统一通过 skills 机制加载
- **D-03:** SKILL.md 内引用 support 文件（references/scripts/hooks）使用仓库内相对路径，不再在安装时做路径重写

### Claude Code 安装
- **D-04:** 添加 `.claude-plugin/plugin.json`，使仓库支持 `/plugin install` 标准安装路径
- **D-05:** plugin.json 中声明 skills 目录、hooks 目录等，遵循 Claude Code 插件规范

### Codex 安装
- **D-06:** 保留并完善 `.codex-plugin/plugin.json` + `.agents/plugins/marketplace.json`，支持 Codex 市场安装
- **D-07:** 保留简化版 symlink 安装脚本，作为市场安装的备选方案

### 目录结构
- **D-08:** 仓库目录结构对标 superpowers：`skills/` + `.claude-plugin/` + `.codex-plugin/` + `references/` + `scripts/` + `hooks/`，仓库本身即为可安装的插件包

### Claude's Discretion
- `.claude-plugin/plugin.json` 的具体字段值（版本号、描述文案）
- 废弃 `claude/commands/` 时的清理策略（直接删除 vs 迁移过渡期）
- symlink 脚本的具体实现细节
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 参考实现
- `https://github.com/obra/superpowers` — superpowers 主仓库，目录结构、plugin.json 格式、skills 规范的参考标准
- `.codex-plugin/plugin.json` — 当前已有的 Codex 插件元数据
- `.agents/plugins/marketplace.json` — 当前已有的 Codex 市场注册文件

### 项目规范
- `CLAUDE.md` — 项目级指令与约束（运行时、安全、语言）
- `README.md` — 当前安装流程文档，Phase 4 需要重写安装章节
- `references/policy.md` — 核心工作流策略（skills 引用的内容源）

### 设计文档
- `docs/superpowers/specs/2026-05-13-git-remote-diagnostics-design.md` — 现有 design doc 格式参考
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `skills/liam-git-workflow*/SKILL.md`（10个）：已经是符合规范的 SKILL.md 格式，无需改动
- `scripts/install.ps1` + `scripts/common.ps1`：现有安装逻辑，需简化为 symlink + plugin.json 模式
- `.codex-plugin/plugin.json` + `.agents/plugins/marketplace.json`：Codex 侧已就绪，可直接复用

### Established Patterns
- 所有技能已使用标准的 SKILL.md frontmatter 格式（name, description）
- `scripts/common.ps1` 封装了目录操作、文件复制、路径重写等工具函数
- 安装元数据写入 `~/.liam-git-workflow/install.json`

### Integration Points
- `skills/SKILL.md` → Claude Code 通过 `.claude/skills/` 自动发现
- `skills/SKILL.md` → Codex 通过 `~/.agents/skills/` 自动发现
- `.claude-plugin/plugin.json` → Claude Code `/plugin install` 入口
</code_context>

<specifics>
## Specific Ideas

- 用户明确要求"跟参考目录一致" — 严格按照 superpowers 的 repo 结构来组织
- 安装体验目标：`git clone` → 一条命令安装 → 可用
</specifics>

<deferred>
## Deferred Ideas

- 官方 marketplace 上架 — Out of scope（PROJECT.md 已声明）
- Cursor / Copilot / Gemini / OpenCode 适配 — Out of scope
- 远端版本检测与升级提醒 — 后续迭代

</deferred>

---
*Phase: 04-superpowers-codex-claude-code*
*Context gathered: 2026-05-25*
