# Phase 05: 元技能引导 — 自动发现与路由

**Gathered:** 2026-05-26
**Status:** Ready for planning

<domain>
## Phase Boundary

对标 superpowers 的 `using-superpowers` 元技能，创建 `liam-git-workflow-bootstrap` 元技能，实现 Git 工作流技能的自动发现、引导和路由。让 Agent 在会话开始时就能感知所有可用 Git 工作流技能，无需用户记忆具体技能名称。

**In scope:**
- 新建 `skills/liam-git-workflow-bootstrap/SKILL.md` — 元技能，列出所有 10 个技能及其触发条件
- 修改 `hooks/hooks.json` — SessionStart additionalContext 指向 bootstrap 技能
- Bootstrap 技能内容：技能清单、触发条件路由表、使用优先级规则

**Out of scope:**
- 修改现有 10 个技能的内容（它们已经工作正常）
- 新增额外的自动化能力（如自动检测当前分支状态并推荐操作）
- 跨平台引导（Codex 侧已有 `liam-git-workflow` 作为路由入口）
</domain>

<decisions>
## Design Decisions (from prior discussion)

### 对标 superpowers
- **D-01:** Bootstrap 技能对标 `using-superpowers` 的 gatekeeper 角色，在会话启动时注入上下文
- **D-02:** 采用"1% 规则"变体：只要用户请求涉及 Git 操作，Agent 就应该考虑是否有对应技能
- **D-03:** Bootstrap 不替代 `liam-git-workflow` 主路由技能，而是作为前置发现层

### 注入方式
- **D-04:** 通过 `hooks/hooks.json` SessionStart 的 additionalContext 注入引导信息
- **D-05:** 不依赖 Claude Code bug #16538 修复 — bootstrap 技能本身可通过 Skill tool 被调用

### 技能清单
- **D-06:** Bootstrap 列出全部 10 个技能，含触发条件、适用场景、示例 prompt
- **D-07:** 路由优先级：bootstrap 引导 → `liam-git-workflow` 主路由 → 具体子技能
</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### 参考实现
- `https://github.com/obra/superpowers/blob/main/skills/using-superpowers/SKILL.md` — using-superpowers 元技能参考（gatekeeper 模式、1% 规则、red flags 表）
- `skills/liam-git-workflow/SKILL.md` — 当前主路由技能，含 10 条路由规则
- `skills/liam-git-workflow-help/SKILL.md` — 当前帮助技能，含技能列表和示例

### 当前项目文件
- `hooks/hooks.json` — SessionStart 钩子配置，需修改 additionalContext
- `.claude-plugin/plugin.json` — 插件 manifest，skills 声明为 `["skills"]`
- `references/policy.md` — 核心工作流策略
</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `skills/liam-git-workflow/SKILL.md`：已有完整的 10 条路由规则，可直接作为 bootstrap 的路由参考
- `skills/liam-git-workflow-help/SKILL.md`：已有技能列表和示例，可作为 bootstrap 内容基础
- `hooks/hooks.json`：SessionStart 钩子已就绪，只需修改 additionalContext 文案

### Current Skills Inventory (10 skills)
| 技能名 | 触发条件 |
|--------|---------|
| `liam-git-workflow` | 默认主入口，自然语言 Git 请求 |
| `liam-git-workflow-help` | 询问可用命令/入口 |
| `liam-git-workflow-create-branch` | 创建/命名分支 |
| `liam-git-workflow-commit` | 提交变更 |
| `liam-git-workflow-sync-branch` | 同步最新基线 |
| `liam-git-workflow-finish` | 完成分支收尾 |
| `liam-git-workflow-hotfix` | 生产问题修复 |
| `liam-git-workflow-release` | 打标签/合并 dev 到 main |
| `liam-git-workflow-sync-policy` | 审计 Git 配置与策略 |
| `liam-git-workflow-remote-diagnose` | 远程操作失败诊断 |

### Established Patterns
- 所有技能使用标准 SKILL.md frontmatter 格式（name, description）
- 技能通过目录名自描述，Claude Code / Codex 自动发现
- 路由技能使用 "Load First" + "Routing Rules" + "Response Style" 三段式结构
- Hooks 使用 inline PowerShell 命令注入 additionalContext
</code_context>

<specifics>
## Specific Ideas

- Bootstrap SKILL.md 结构：技能清单表 → 触发条件路由 → 使用优先级 → 示例
- additionalContext 文案：简洁引导，指向 bootstrap 技能，不重复完整技能清单
- 保持与 `liam-git-workflow` 路由规则的一致性，避免两套路由逻辑分歧
- Bootstrap 在被调用时应能列出所有技能并主动提供路由
</specifics>

<deferred>
## Deferred Ideas

- 自动检测当前仓库状态（分支名、未提交变更、未推送提交）并主动推荐技能 — 后续迭代
- Codex 侧对应的 Codex 版本 bootstrap（当前 Codex 已有 `liam-git-workflow` 作为主入口，够用）
- 多语言支持（英文引导） — 当前仅中文
</deferred>

---
*Phase: 05-meta-skill-bootstrap*
*Context gathered: 2026-05-26*
