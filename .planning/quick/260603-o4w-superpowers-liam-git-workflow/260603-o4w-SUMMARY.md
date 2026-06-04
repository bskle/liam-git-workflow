---
phase: quick-o4w-superpowers
plan: 01
subsystem: skills
tags: [cli, claude-code, skills, slash-commands, naming, superpowers]
requires: []
provides:
  - 11 skill directories renamed from liam-git-workflow(-*) to gw(-*) short names
  - All cross-references updated across skill bodies and hooks.json
  - Slash commands shortened 60-80% (e.g. /liam-git-workflow-commit (29 chars) -> /gw-commit (10 chars))
affects: [all git-workflow skills, bootstrap, hooks, session-start]

tech-stack:
  added: []
  patterns:
    - Short skill name convention: gw(-*) matching superpowers style
    - All 11 directory names match frontmatter `name` fields exactly

key-files:
  created: []
  modified:
    - skills/gw/SKILL.md (routing rules + response style)
    - skills/gw-bootstrap/SKILL.md (skill roster table + all sections)
    - skills/gw-help/SKILL.md (entry list)
    - skills/gw-commit/SKILL.md (frontmatter name)
    - skills/gw-create-branch/SKILL.md (frontmatter name)
    - skills/gw-sync/SKILL.md (troubleshooting ref)
    - skills/gw-finish/SKILL.md (frontmatter name)
    - skills/gw-hotfix/SKILL.md (frontmatter name)
    - skills/gw-release/SKILL.md (frontmatter name)
    - skills/gw-sync-policy/SKILL.md (frontmatter name)
    - skills/gw-diagnose/SKILL.md (manual trigger + frontmatter name)
    - hooks/hooks.json (SessionStart additionalContext)

key-decisions:
  - "Renamed 11 skill directories from liam-git-workflow(-*) to gw(-*) to match superpowers short-name convention"
  - "plugin.json 'name': 'liam-git-workflow' kept unchanged -- plugin identity is separate from skill command names"
  - "references/ directory files left untouched -- policy files contain no skill name self-references"

patterns-established:
  - "Short skill name convention: gw as main router, gw-* as sub-skills"

requirements-completed: ["QUICK-o4w-superpowers"]

duration: 5min
completed: 2026-06-04
---

# Quick Task o4w: 技能名称缩短 -- 对标 superpowers 命名模式

**将 11 个技能目录从 22-37 字符的 `liam-git-workflow(-*)` 缩短为 4-16 字符的 `gw(-*)` 模式，斜杠命令长度缩减 60-80%**

## Performance

- **Duration:** ~5 min
- **Tasks:** 2
- **Files modified:** 12

## Accomplishments
- 11 个技能目录通过 `git mv` 重命名，保留 git 历史追踪
- 11 个 SKILL.md frontmatter `name` 字段全部更新为新名称
- Main router (gw) 的 10 条路由规则全部更新为新的 `gw-*` 子技能引用
- Bootstrap 技能清单表格 10 行全部使用新名称和短斜杠命令
- Help 技能入口列表 10 个全部更新为 `$gw-*` 格式
- Sync -> Diagnose 交叉引用更新
- hooks.json SessionStart 消息更新为 `/gw-bootstrap` 和 `/gw`
- 全局零残留 `liam-git-workflow` 字符串

## Task Commits

1. **Task 1: 重命名目录 + 更新 frontmatter name** - `68cd974` (feat)
2. **Task 2: 更新 body 交叉引用 + hooks.json** - `5222b22` (feat)

## Files Created/Modified

- `skills/gw/SKILL.md` - 主路由规则全部更新为 gw-* 引用
- `skills/gw-bootstrap/SKILL.md` - 技能清单表格 + 所有章节更新（31 处修改）
- `skills/gw-help/SKILL.md` - 入口列表 10 个全部更新
- `skills/gw-sync/SKILL.md` - Troubleshooting 交叉引用更新
- `skills/gw-diagnose/SKILL.md` - Manual Trigger 自引用更新
- `skills/gw-commit/SKILL.md` - frontmatter name 更新
- `skills/gw-create-branch/SKILL.md` - frontmatter name 更新
- `skills/gw-finish/SKILL.md` - frontmatter name 更新
- `skills/gw-hotfix/SKILL.md` - frontmatter name 更新
- `skills/gw-release/SKILL.md` - frontmatter name 更新
- `skills/gw-sync-policy/SKILL.md` - frontmatter name 更新
- `hooks/hooks.json` - SessionStart 消息短命令更新

## Decisions Made

- plugin.json `"name": "liam-git-workflow"` 保持不变（插件标识，与技能命令名独立）
- references/ 政策文件不修改（纯内容文件，无技能名称引用）

## Deviations from Plan

None - plan executed exactly as written. The Task 1 commit was detected as a pure rename (100% similarity), so 6 frontmatter name changes from simple SKILL.md files were automatically included in the Task 2 commit.

## Issues Encountered

None.

