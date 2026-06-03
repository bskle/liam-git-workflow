---
phase: quick-nbx-superpowers
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - skills/liam-git-workflow-bootstrap/SKILL.md
  - hooks/hooks.json
  - .claude-plugin/plugin.json
autonomous: false
requirements: ["QUICK-nbx-slash-commands"]

must_haves:
  truths:
    - "用户在 Claude Code 中输入 /liam 即可在命令补全列表中看到全部 10 个 Git 工作流斜杠命令"
    - "每个斜杠命令有清晰的中文描述，用户无需查文档即可理解命令用途"
    - "SessionStart hook 提示用户可通过 /liam-git-workflow-bootstrap 发现全部技能"
  artifacts:
    - path: "skills/liam-git-workflow-bootstrap/SKILL.md"
      provides: "斜杠命令清单文档（表格新增『斜杠命令』列）"
      contains: "斜杠命令"
    - path: "hooks/hooks.json"
      provides: "SessionStart 斜杠命令发现提示"
      contains: "/liam-git-workflow-bootstrap"
  key_links:
    - from: ".claude-plugin/plugin.json"
      to: "skills/ 目录"
      via: "skills 字段值 [\"skills\"]"
      pattern: "\"skills\":\\s*\\[\"skills\"\\]"
    - from: "hooks/hooks.json SessionStart"
      to: "bootstrap SKILL.md"
      via: "斜杠命令 /liam-git-workflow-bootstrap 引导 Agent 查询技能清单"
---
# 添加斜杠命令支持

<objective>
确保 liam-git-workflow 的全部 10 个技能在 Claude Code 插件系统中作为斜杠命令可发现和可调用。Claude Code 会自动将 `skills/` 目录下每个子目录名注册为 `/skill-name` 斜杠命令，本计划做结构审计和文档增强，确保用户知道如何通过斜杠命令直接调用各项技能。
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
<interfaces>
现有技能目录结构（10个技能）:
```
skills/
  liam-git-workflow/            → /liam-git-workflow (自然语言主路由)
  liam-git-workflow-bootstrap/  → /liam-git-workflow-bootstrap (元技能发现入口)
  liam-git-workflow-help/       → /liam-git-workflow-help (命令列表)
  liam-git-workflow-commit/     → /liam-git-workflow-commit (提交)
  liam-git-workflow-create-branch/ → /liam-git-workflow-create-branch (分支创建)
  liam-git-workflow-sync-branch/   → /liam-git-workflow-sync-branch (同步)
  liam-git-workflow-finish/        → /liam-git-workflow-finish (收尾)
  liam-git-workflow-hotfix/        → /liam-git-workflow-hotfix (紧急修复)
  liam-git-workflow-release/       → /liam-git-workflow-release (发布)
  liam-git-workflow-sync-policy/   → /liam-git-workflow-sync-policy (策略审计)
  liam-git-workflow-remote-diagnose/ → /liam-git-workflow-remote-diagnose (远程诊断)
```

plugin.json 已有 `"skills": ["skills"]` 字段，Claude Code 会自动发现并注册。

Bootstrap 技能作为元技能入口，对标 superpowers 的 `using-superpowers`，已有完整的技能清单和路由规则。
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: 斜杠命令结构审计</name>
  <files>skills/*/SKILL.md</files>
  <action>
审计全部 10 个技能目录，确保斜杠命令自动注册能正常工作。检查项：

1. **SKILL.md frontmatter 完整性**：每个 `skills/*/SKILL.md` 必须包含 `name` 和 `description` 字段（Claude Code 用 `name` 注册命令，用 `description` 显示命令描述）。逐文件检查：
   - `skills/liam-git-workflow/SKILL.md`
   - `skills/liam-git-workflow-bootstrap/SKILL.md`
   - `skills/liam-git-workflow-help/SKILL.md`
   - `skills/liam-git-workflow-commit/SKILL.md`
   - `skills/liam-git-workflow-create-branch/SKILL.md`
   - `skills/liam-git-workflow-sync-branch/SKILL.md`
   - `skills/liam-git-workflow-finish/SKILL.md`
   - `skills/liam-git-workflow-hotfix/SKILL.md`
   - `skills/liam-git-workflow-release/SKILL.md`
   - `skills/liam-git-workflow-sync-policy/SKILL.md`
   - `skills/liam-git-workflow-remote-diagnose/SKILL.md`

2. **目录名与 SKILL.md name 一致性**：每个技能目录名必须匹配其 SKILL.md frontmatter 中的 `name` 值（Claude Code 用目录名注册，但 frontmatter name 是技能标识，两者一致避免混淆）。

3. **plugin.json 验证**：确认 `"skills": ["skills"]` 字段正确指向技能目录。

4. 审计结果写入终端输出，列出通过/不通过的技能。如有问题，直接修复 SKILL.md frontmatter。
  </action>
  <verify>
    <automated>bash -c 'for d in skills/*/; do name=$(grep "^name:" "$d/SKILL.md" 2>/dev/null | head -1); desc=$(grep "^description:" "$d/SKILL.md" 2>/dev/null | head -1); dirname=$(basename "$d"); if [ -z "$name" ] || [ -z "$desc" ]; then echo "MISSING: $dirname"; else echo "OK: $dirname → $name"; fi; done'</automated>
  </verify>
  <done>全部 10 个技能 SKILL.md frontmatter 完整，目录名与 name 字段一致，plugin.json skills 字段正确。斜杠命令结构可用于自动注册。</done>
</task>

<task type="auto">
  <name>Task 2: 斜杠命令可发现性增强</name>
  <files>
    skills/liam-git-workflow-bootstrap/SKILL.md
    hooks/hooks.json
  </files>
  <action>
在 bootstrap 技能和 SessionStart hook 中增加斜杠命令的使用说明，让用户知道如何直接通过斜杠调用技能。

**bootstrap SKILL.md 修改：**

在第 3 节「技能清单」的表格中，为每个技能增加一列「斜杠命令」，展示对应的 `/` 命令。在表格前加一句引导说明：「所有技能在 Claude Code 中作为斜杠命令直接可用，输入 `/` 即可触发命令补全列表。」

更新后的表格新增列：
```
| 技能名称 | 斜杠命令 | 触发场景 | 典型请求示例 |
```

在第 6 节「使用示例」中，每个示例增加「斜杠方式」小节，展示如何通过 slah 命令触发：

- 示例 1: 可直接输入 `/liam-git-workflow-commit` 调用提交技能
- 示例 2: 可直接输入 `/liam-git-workflow-release` 调用发布技能
- 示例 3: 可直接输入 `/liam-git-workflow-remote-diagnose` 调用诊断技能

**hooks/hooks.json 修改：**

更新 SessionStart hook 的输出消息，增加斜杠命令提示：

当前消息末尾追加：「Use /liam-git-workflow-bootstrap to discover all 10 skills as slash commands, or /liam-git-workflow for natural-language routing. Type / and browse the command list.」

确保命令执行正常（PowerShell 单行 JSON，不引入转义问题）。
  </action>
  <verify>
    <automated>bash -c 'echo "=== bootstrap 斜杠命令说明 ===" && grep -c "斜杠命令" skills/liam-git-workflow-bootstrap/SKILL.md && echo "=== hooks 斜杠消息 ===" && grep -c "/liam-git-workflow-bootstrap" hooks/hooks.json && echo "=== 表格新增列检查 ===" && grep -c "| 技能名称 | 斜杠命令 |" skills/liam-git-workflow-bootstrap/SKILL.md'</automated>
  </verify>
  <done>bootstrap SKILL.md 表格新增「斜杠命令」列，示例增加斜杠调用方式。hooks.json SessionStart 消息提及斜杠命令语法和 bootstrap 入口。用户输入 `/` 后可浏览全部 10 个 Git 工作流命令。</done>
</task>

</tasks>

<success_criteria>

## 结构审计
- [ ] 全部 10 个技能 SKILL.md 有完整的 `name` 和 `description` frontmatter
- [ ] 技能目录名与 SKILL.md `name` 字段一致
- [ ] plugin.json `skills` 字段正确指向 `skills` 目录

## 可发现性
- [ ] bootstrap 技能清单表格包含「斜杠命令」列
- [ ] bootstrap 使用示例展示斜杠调用方式
- [ ] hooks.json SessionStart 消息提及斜杠命令入口
- [ ] 用户在 Claude Code 中输入 `/liam` 即可看到全部 Git 工作流命令自动补全

</success_criteria>

<output>
After completion, create `.planning/quick/260603-nbx-superpowers-superpowers-brainstorming-li/260603-nbx-SUMMARY.md`
</output>
