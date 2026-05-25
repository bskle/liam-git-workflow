<!-- GSD:project-start source:PROJECT.md -->
## Project

**Liam Git Workflow**

面向 Codex 和 Claude Code 的个人 Git 工作流插件包。把 Git 分支管理、提交规范、同步策略等日常操作收敛到统一入口，通过技能路由和自然语言交互完成 Git 工作，避免依赖零散记忆或临时 prompt。

**Core Value:** **让 Agent 能自主完成完整的 Git 工作流** — 从分支创建、提交、同步到远程诊断，无需人工逐条记忆规则。

### Constraints

- **运行时**: Windows 11, PowerShell 5.1+, Git 2.40+
- **语言**: 提交信息必须中文，代码注释和文档使用中文
- **安全**: 危险 Git 操作（force push, hard reset）需人工确认
- **环境**: 依赖 Codex/Claude Code 的技能/命令系统，不引入额外运行时依赖
<!-- GSD:project-end -->

<!-- GSD:stack-start source:STACK.md -->
## Technology Stack

Technology stack not yet documented. Will populate after codebase mapping or first phase.
<!-- GSD:stack-end -->

<!-- GSD:conventions-start source:CONVENTIONS.md -->
## Conventions

Conventions not yet established. Will populate as patterns emerge during development.
<!-- GSD:conventions-end -->

<!-- GSD:architecture-start source:ARCHITECTURE.md -->
## Architecture

Architecture not yet mapped. Follow existing patterns found in the codebase.
<!-- GSD:architecture-end -->

<!-- GSD:skills-start source:skills/ -->
## Project Skills

No project skills found. Add skills to any of: `.claude/skills/`, `.agents/skills/`, `.cursor/skills/`, or `.github/skills/` with a `SKILL.md` index file.
<!-- GSD:skills-end -->

<!-- GSD:workflow-start source:GSD defaults -->
## GSD Workflow Enforcement

Before using Edit, Write, or other file-changing tools, start work through a GSD command so planning artifacts and execution context stay in sync.

Use these entry points:
- `/gsd-quick` for small fixes, doc updates, and ad-hoc tasks
- `/gsd-debug` for investigation and bug fixing
- `/gsd-execute-phase` for planned phase work

Do not make direct repo edits outside a GSD workflow unless the user explicitly asks to bypass it.
<!-- GSD:workflow-end -->



<!-- GSD:profile-start -->
## Developer Profile

> Profile not yet configured. Run `/gsd-profile-user` to generate your developer profile.
> This section is managed by `generate-claude-profile` -- do not edit manually.
<!-- GSD:profile-end -->
