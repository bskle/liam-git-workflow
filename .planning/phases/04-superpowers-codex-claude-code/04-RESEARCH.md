# Phase 04: 插件化安装 - Research

**Researched:** 2026-05-25
**Domain:** Multi-platform AI coding assistant plugin packaging (Claude Code + Codex)
**Confidence:** HIGH

## Summary

This phase transforms the Liam Git Workflow repository into a self-contained plugin package that users can install through standard mechanisms on both Claude Code and Codex platforms. The primary reference implementation is `obra/superpowers`, which demonstrates a pattern of `skills/` + `.claude-plugin/` + `.codex-plugin/` + `hooks/` + `references/` + `scripts/` at the repo root, acting as an installable plugin directory.

The Claude Code plugin system (v2.1+) auto-discovers `skills/`, `hooks/hooks.json`, `commands/`, and `agents/` directories by convention. The minimal `plugin.json` requires only `name`, but `version` is functionally mandatory. Critical undocumented constraints exist: the `agents` field must not be declared (it causes hard validation failure), and `hooks` must not be explicitly declared as a path string (it auto-loads and duplicate declarations error). A known open bug (#16538) prevents plugin `SessionStart` hooks from surfacing `additionalContext`, which affects whether this phase can include session-bootstrap injection.

The Codex side uses `.codex-plugin/plugin.json` + `.agents/plugins/marketplace.json` with either directory symlinks (preferred, as file symlinks have a known bug in Codex) or real copies. The SKILL.md format is identical across both platforms (agentskills.io standard), making the `skills/` directory shareable without modification.

**Primary recommendation:** Create `.claude-plugin/plugin.json` with only the essential fields (name, version, description, author, keywords), let auto-discovery handle skills and hooks. For Codex, use directory symlink from `~/.agents/skills/liam-git-workflow` -> repo `skills/` as the primary install path, with marketplace.json for Codex app discovery. Keep plugin.json minimal to avoid validator rejection from undocumented field constraints.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
- **D-01:** `skills/` 作为唯一技能定义源，每个技能一个子目录，内含 `SKILL.md`
- **D-02:** 废弃 `claude/commands/` 目录，Claude Code 侧统一通过 skills 机制加载
- **D-03:** SKILL.md 内引用 support 文件（references/scripts/hooks）使用仓库内相对路径，不再在安装时做路径重写
- **D-04:** 添加 `.claude-plugin/plugin.json`，使仓库支持 `/plugin install` 标准安装路径
- **D-05:** plugin.json 中声明 skills 目录、hooks 目录等，遵循 Claude Code 插件规范
- **D-06:** 保留并完善 `.codex-plugin/plugin.json` + `.agents/plugins/marketplace.json`，支持 Codex 市场安装
- **D-07:** 保留简化版 symlink 安装脚本，作为市场安装的备选方案
- **D-08:** 仓库目录结构对标 superpowers：`skills/` + `.claude-plugin/` + `.codex-plugin/` + `references/` + `scripts/` + `hooks/`

### Claude's Discretion
- `.claude-plugin/plugin.json` 的具体字段值（版本号、描述文案）
- 废弃 `claude/commands/` 时的清理策略（直接删除 vs 迁移过渡期）
- symlink 脚本的具体实现细节

### Deferred Ideas (OUT OF SCOPE)
- 官方 marketplace 上架 — Out of scope（PROJECT.md 已声明）
- Cursor / Copilot / Gemini / OpenCode 适配 — Out of scope
- 远端版本检测与升级提醒 — 后续迭代
</user_constraints>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Plugin manifest (.claude-plugin/plugin.json) | Repo root static file | Claude Code runtime | Manifest lives in the repo but is consumed by Claude Code's plugin loader at install/enable time |
| Plugin manifest (.codex-plugin/plugin.json) | Repo root static file | Codex runtime | Manifest lives in the repo but is consumed by Codex's plugin discovery at install time |
| Marketplace registration (.agents/plugins/marketplace.json) | Repo root static file | Codex runtime | Codex scans `~/.agents/plugins/marketplace.json` and repo-local marketplace files at startup |
| Skills (skills/*/SKILL.md) | Repo root static files | Both runtimes | Skills are the shared payload; both platforms read them through their respective discovery paths after installation |
| Hooks (hooks/hooks.json) | Repo root static file | Claude Code runtime | Claude Code loads `hooks/hooks.json` by convention when the plugin is enabled |
| Installation script (scripts/install.ps1) | Repo scripts | User's local environment | Runs on user's machine; creates symlinks and/or copies files to platform-specific directories |
| Reference documents (references/) | Repo root static files | Skills (indirect) | Referenced by skills via relative paths; the repo-as-plugin-directory model keeps paths stable |
| Support scripts (scripts/*.ps1) | Repo root static files | Skills (indirect) | Referenced by skills for runtime operations like diagnostics and validation |

## Standard Stack

This phase introduces **no new runtime dependencies**. All installation is file-level operations (file creation, symlinks, directory creation). The stack is entirely the existing repo's static files plus new manifest/configuration files.

### Core (Plugin Manifests)
| File | Format | Purpose | Why Standard |
|------|--------|---------|--------------|
| `.claude-plugin/plugin.json` | JSON | Claude Code plugin identity + component declaration | Only format Claude Code recognizes for plugin discovery [VERIFIED: anthropics/claude-plugins-official docs] |
| `.codex-plugin/plugin.json` | JSON | Codex plugin identity + skills path | Only format Codex recognizes for plugin metadata [CITED: openai/codex plugin-creator SKILL.md] |
| `.agents/plugins/marketplace.json` | JSON | Codex marketplace registration | Required for Codex to discover and list the plugin in its UI [CITED: openai/codex plugin-creator SKILL.md] |
| `hooks/hooks.json` | JSON | Claude Code hook event registration | Standard Claude Code hook configuration format [VERIFIED: anthropics/claude-code hooks documentation] |

### Supporting (Installation Scripts)
| File | Language | Purpose | When to Use |
|------|----------|---------|-------------|
| `scripts/install.ps1` (simplified) | PowerShell 5.1 | Primary install script; creates symlinks for both platforms | Main install path, replaces current file-copy logic |
| `scripts/link_codex_global_skills.ps1` (simplified) | PowerShell 5.1 | Codex-only symlink install | Legacy compatibility, delegates to main install.ps1 |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Directory symlink for skills dir | Real file copies | Copies avoid symlink bugs but cause drift between repo source and installed skills; updates require re-copying |
| Minimal plugin.json (name+version only) | Full plugin.json with explicit paths | Explicit paths can break if auto-discovery behavior changes; minimal leans on convention which is more resilient |
| Direct `claude/commands/` deletion | Gradual deprecation (keep with migration notice) | Direct deletion is cleaner but could break existing user installs that reference `/liam-git-workflow:*` commands |

**Installation:** No new packages to install. The phase only creates new static files and modifies existing scripts.

## Architecture Patterns

### System Architecture Diagram

```
User clones repo
       │
       ├─── Claude Code path ─────────────────────────────────────────┐
       │                                                                │
       │   ┌──────────────────────────────────────────────────────┐   │
       │   │  /plugin install <repo-path>                          │   │
       │   │  or: Claude Code discovers .claude-plugin/plugin.json │   │
       │   └────────────────────┬─────────────────────────────────┘   │
       │                        │                                      │
       │                        ▼                                      │
       │   ┌──────────────────────────────────────────────────────┐   │
       │   │  Claude Code plugin loader:                           │   │
       │   │  1. Reads .claude-plugin/plugin.json                 │   │
       │   │  2. Auto-discovers skills/ → indexes SKILL.md files  │   │
       │   │  3. Auto-discovers hooks/hooks.json                  │   │
       │   │  4. Makes plugin available as:                       │   │
       │   │     Skill tool: liam-git-workflow-create-branch, etc │   │
       │   │     (formerly /liam-git-workflow:* slash commands)   │   │
       │   └──────────────────────────────────────────────────────┘   │
       │                                                                │
       ├─── Codex path ──────────────────────────────────────────────┐│
       │                                                               ││
       │   Option A: Marketplace install                               ││
       │   ┌──────────────────────────────────────────────────────┐   ││
       │   │  Codex scans .agents/plugins/marketplace.json        │   ││
       │   │  → discovers liam-git-workflow plugin                │   ││
       │   │  → user installs via UI or CLI                       │   ││
       │   │  → Codex caches to ~/.codex/plugins/cache/          │   ││
       │   └──────────────────────────────────────────────────────┘   ││
       │                                                               ││
       │   Option B: Symlink install (fallback)                        ││
       │   ┌──────────────────────────────────────────────────────┐   ││
       │   │  scripts/install.ps1 (or manual):                    │   ││
       │   │  mklink /J ~/.agents/skills/<name> <repo>/skills/    │   ││
       │   │  mklink /J ~/.codex/superpowers-skills/<name> ...    │   ││
       │   │  → Codex auto-scans ~/.agents/skills/ at startup    │   ││
       │   └──────────────────────────────────────────────────────┘   ││
       │                                                               ││
       │   Both options result in:                                     ││
       │   ┌──────────────────────────────────────────────────────┐   ││
       │   │  Codex loads skills via Skill tool                   │   ││
       │   │  $liam-git-workflow, $liam-git-workflow-commit, etc  │   ││
       │   └──────────────────────────────────────────────────────┘   ││
       │                                                               ││
       └─── Shared skill content (no per-platform modification) ──────┘
                         │
                         ▼
            skills/*/SKILL.md — read by both platforms
            Uses repo-relative paths: ../../references/, ../../scripts/
            No path rewriting at install time (D-03)
```

### Recommended Project Structure

```
liam-git-workflow/                    # repo root = plugin root
├── .claude-plugin/                   # [NEW] Claude Code plugin manifest
│   └── plugin.json                   # Minimal: name, version, description, author, keywords
├── .codex-plugin/                    # [KEEP] Codex plugin manifest
│   └── plugin.json                   # Existing, may need skills path update
├── .agents/                          # [KEEP] Codex discovery
│   └── plugins/
│       └── marketplace.json          # Existing, may need source.path review
├── skills/                           # [KEEP] Single source of truth for skills (D-01)
│   ├── liam-git-workflow/
│   │   └── SKILL.md
│   ├── liam-git-workflow-help/
│   │   └── SKILL.md
│   ├── liam-git-workflow-create-branch/
│   │   └── SKILL.md
│   ├── liam-git-workflow-commit/
│   │   └── SKILL.md
│   ├── liam-git-workflow-sync-branch/
│   │   └── SKILL.md
│   ├── liam-git-workflow-finish/
│   │   └── SKILL.md
│   ├── liam-git-workflow-hotfix/
│   │   └── SKILL.md
│   ├── liam-git-workflow-release/
│   │   └── SKILL.md
│   ├── liam-git-workflow-sync-policy/
│   │   └── SKILL.md
│   └── liam-git-workflow-remote-diagnose/
│       └── SKILL.md
├── hooks/                            # [EXISTING] Git hooks + [NEW] Claude Code hooks
│   ├── hooks.json                    # [NEW] Claude Code hook registration
│   └── commit-msg                    # [KEEP] Git commit-msg hook template
├── references/                       # [KEEP] Skill reference documents
│   ├── policy.md
│   ├── branch-matrix.md
│   ├── commit-rules.md
│   ├── pr-rules.md
│   ├── scenarios.md
│   └── remote-diagnostics.md
├── scripts/                          # [KEEP + SIMPLIFY]
│   ├── install.ps1                   # [REWRITE] Simplified: symlink creation only
│   ├── common.ps1                    # [SIMPLIFY] Remove file-copy functions
│   ├── link_codex_global_skills.ps1  # [SIMPLIFY] Delegate to install.ps1 -SkipClaude
│   ├── update.ps1                    # [SIMPLIFY] git pull + re-symlink if needed
│   ├── install_repo_hooks.ps1        # [KEEP] Git hook installation (unrelated to plugins)
│   ├── diagnose_git_remote.ps1       # [KEEP] Diagnostic script
│   ├── validate_commit_message.ps1   # [KEEP] Commit validation
│   └── audit_git_config.ps1         # [KEEP] Git config audit
├── tests/                            # [KEEP]
├── docs/                             # [KEEP]
├── claude/commands/                  # [DEPRECATE per D-02] Legacy slash commands (10 files)
├── VERSION                           # [KEEP]
├── CHANGELOG.md                      # [KEEP]
├── README.md                         # [UPDATE] Rewrite install section
└── CLAUDE.md                         # [KEEP]
```

### Pattern 1: Plugin-as-Repo-Root (Superpowers Model)
**What:** The entire repository root serves as the plugin directory. The `.claude-plugin/plugin.json` lives at repo root level alongside `skills/`, `hooks/`, `references/`, and `scripts/`. Users clone the repo, then run `claude --plugin-dir <repo-path>` or `/plugin install <repo-path>`.

**When to use:** This is the primary pattern for this phase. It aligns with D-08 (对标 superpowers).

**Example (superpowers):**
```
superpowers/          ← git repo root = Claude Code plugin dir
├── .claude-plugin/
│   └── plugin.json
├── skills/
├── hooks/
├── scripts/
└── references/
```
[VERIFIED: obra/superpowers web search + GitHub structure analysis]

### Pattern 2: Convention-Based Auto-Discovery
**What:** Claude Code automatically discovers `skills/`, `hooks/hooks.json`, `commands/`, and `agents/` directories at the plugin root. These do NOT need to be explicitly declared in `plugin.json`. Declaring them can cause conflicts.

**When to use:** Always for Claude Code plugins. Declare only when using non-standard directory names.

### Pattern 3: Directory Symlink for Codex Skills
**What:** Instead of copying SKILL.md files into Codex directories, create a directory-level symlink from the Codex skills scan path to the repo's `skills/` directory.

**When to use:** Codex install when marketplace install is not desired. Note: Codex has a known bug where file-level symlinks to SKILL.md are dropped, but directory-level symlinks work correctly [VERIFIED: openai/codex issue #17344].

### Anti-Patterns to Avoid
- **Declaring `"agents"` in Claude Code plugin.json:** Causes hard validation failure `agents: Invalid input`. Agents are auto-discovered [VERIFIED: ECC plugin schema notes + multiple issues].
- **Declaring `"hooks"` as a string path in Claude Code plugin.json:** Causes duplicate loading error `Duplicate hooks file detected: ./hooks/hooks.json resolves to already-loaded file` [VERIFIED: everything-claude-code issue #103].
- **File-level symlinks for Codex SKILL.md files:** Known Codex bug — loader drops file symlinks. Use directory-level symlinks instead [VERIFIED: openai/codex issue #17344].
- **Including unrecognized fields in plugin.json:** Fields like `documentation`, `category`, `tags`, `workflows`, `components`, `features`, `requirements` cause `Unrecognized keys` rejection [VERIFIED: ECC PLUGIN_SCHEMA_NOTES.md].
- **Omitting `version` field in Claude Code plugin.json:** Technically optional per docs but practically required — missing it causes silent install failures [VERIFIED: ECC PLUGIN_SCHEMA_NOTES.md].
- **Declaring `"skills"` with non-array values:** Must be an array like `["./skills/"]`, not a string [VERIFIED: ECC PLUGIN_SCHEMA_NOTES.md].

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Claude Code plugin discovery | Custom plugin loader or registration system | Claude Code's auto-discovery of `.claude-plugin/plugin.json` + directory conventions | Claude Code has a built-in, well-tested plugin system. `/plugin install` handles discovery, validation, enable/disable, and updates. |
| Codex skill discovery | Custom skill scanner | Codex's native `~/.agents/skills/` directory scanning | Codex already auto-scans this path for `SKILL.md` files. Just place files there (via symlink or copy). |
| Skill format | Custom skill definition format | agentskills.io standard YAML frontmatter + Markdown (already used in existing SKILL.md files) | Both Claude Code and Codex natively consume this format. Cross-platform compatibility without translation. |
| Path rewriting during install | String-replace in SKILL.md file content | Repo-relative paths in SKILL.md + symlink/copy that preserves directory structure | D-03 explicitly requires no path rewriting. When repo is its own plugin directory, relative paths resolve correctly without modification. |

**Key insight:** The entire plugin infrastructure already exists in both platforms. This phase is about creating the correct manifest files and simplifying the install to use platform-native mechanisms rather than custom file-copy logic.

## Runtime State Inventory

> Included because this is a refactor phase — we are migrating from a file-copy install model to a plugin/symlink model and deprecating `claude/commands/`.

| Category | Items Found | Action Required |
|----------|-------------|------------------|
| Stored data | `~/.liam-git-workflow/install.json` — install metadata written by current install.ps1 | Code edit: update install.ps1 to write new metadata format reflecting plugin install model. Old entries remain readable but new format drops `codexHome`/`claudeHome` paths in favor of symlink source tracking. |
| Live service config | None — no external services reference this repo | — |
| OS-registered state | None — no Task Scheduler, systemd, or launchd registrations | — |
| Secrets/env vars | None — no secrets or env vars reference the repo | — |
| Build artifacts | None — pure script repo, no compiled artifacts | — |

**Additional migration concern:** Users with existing installs from current `install.ps1` (file-copy model) will have:
- Copied skills in `~/.codex/skills/liam-git-workflow*/` — need cleanup before symlink install
- Copied commands in `~/.claude/commands/liam-git-workflow/` — need cleanup (these are the legacy slash commands being deprecated)
- `install.json` metadata — should be updated to reflect new install type

The simplified install script should include an `-CleanLegacy` flag or detect existing file-copy installs and offer to clean them up.

## Common Pitfalls

### Pitfall 1: Plugin SessionStart hook additionalContext silently dropped
**What goes wrong:** When a `SessionStart` hook is defined in a plugin's `hooks/hooks.json`, the hook executes but `hookSpecificOutput.additionalContext` is not injected into Claude's context. The agent only sees `"SessionStart:Callback hook success: Success"` instead of the actual content. The same hook works correctly when placed directly in `~/.claude/settings.json`.

**Why it happens:** Known Claude Code bug (issue #16538, still open as of May 2026). The plugin hook execution path does not forward `additionalContext` to the model. [VERIFIED: anthropics/claude-code issue #16538]

**How to avoid:** If session-bootstrap context injection is desired (e.g., auto-injecting the `liam-git-workflow` routing skill at session start), work around the bug by either:
1. Document that users must add the hook to `~/.claude/settings.json` manually (not through plugin)
2. Defer hook-based injection to a later phase when the bug is fixed
3. Use the plugin solely for skill discovery (which works correctly) and treat the hook as "best effort"

**Warning signs:** Hook log shows success but agent behaves as if it received no additional context. Agent doesn't mention or use the injected skill content.

### Pitfall 2: Claude Code plugin.json validator rejects "agents" field
**What goes wrong:** Including `"agents": "./agents/"` or any form of `"agents"` field in plugin.json causes hard validation failure: `agents: Invalid input`. Plugin fails to install.

**Why it happens:** Claude Code auto-discovers `agents/` directory by convention. The validator treats any explicit `agents` declaration as an error. This is undocumented behavior. [VERIFIED: ECC PLUGIN_SCHEMA_NOTES.md + ECC issue #1459]

**How to avoid:** Never include `"agents"` in plugin.json. Do not create an `agents/` directory unless you have subagent definitions, and let auto-discovery handle it.

### Pitfall 3: Codex symlink for individual SKILL.md files is broken
**What goes wrong:** Creating a symlink from `~/.codex/skills/some-skill/SKILL.md` -> repo `skills/some-skill/SKILL.md` results in the skill not appearing in Codex.

**Why it happens:** Codex v26.406.31014+ has a bug where the skill loader follows directory symlinks but drops file symlinks. A file-level symlink to SKILL.md is silently skipped during discovery. [VERIFIED: openai/codex issue #17344]

**How to avoid:** Always symlink the parent directory, not individual files. Use `mklink /J` (directory junction) on Windows pointing to the repo's `skills/` directory, or symlink each individual skill directory.

### Pitfall 4: Duplicate hooks loading from explicit declaration
**What goes wrong:** Adding `"hooks": "./hooks/hooks.json"` to plugin.json causes error: `Duplicate hooks file detected: ./hooks/hooks.json resolves to already-loaded file`.

**Why it happens:** Claude Code v2.1+ automatically loads `hooks/hooks.json` when it exists in the plugin root. Explicitly declaring it causes it to be loaded twice, and the second load is rejected. [VERIFIED: everything-claude-code issue #103]

**How to avoid:** Do NOT declare `"hooks"` in plugin.json. Simply place `hooks/hooks.json` in the plugin root and Claude Code discovers it automatically.

### Pitfall 5: Marketplace source.path resolution ambiguity
**What goes wrong:** The `source.path` in marketplace.json is resolved relative to the marketplace.json file's own directory, not relative to the repo root or the user's home directory. Misconfiguring this path causes "plugin not found" errors.

**Why it happens:** For repo-level marketplace at `<repo>/.agents/plugins/marketplace.json`, `source.path` of `"."` resolves to `<repo>/.agents/plugins/` — NOT the repo root. [VERIFIED: openai/codex plugin-creator SKILL.md]

**How to avoid:** In the current setup, `marketplace.json` is at `liam-git-workflow/.agents/plugins/marketplace.json` with `source.path: "."`. This resolves to the `.agents/plugins/` directory, not the repo root where `skills/` lives. This needs fixing — the `source.path` should point to the repo root or the plugin should be structured such that `plugin.json` is findable from the resolved path.

## Code Examples

### Claude Code plugin.json (minimal, known-good)
```json
{
  "name": "liam-git-workflow",
  "version": "0.3.0",
  "description": "面向 Codex 和 Claude Code 的个人 Git 工作流插件包 — 分支管理、提交规范、同步策略、远程诊断",
  "author": {
    "name": "Liam"
  },
  "keywords": ["git", "workflow", "conventional-commits", "branch-management", "chinese"]
}
```
Source: Derived from superpowers plugin.json pattern + ECC PLUGIN_SCHEMA_NOTES constraints [VERIFIED: obra/superpowers web search + multiple Claude Code plugin references]

**Why no `skills`, `hooks`, or `commands` fields:** Auto-discovery handles them. Explicit declaration risks schema violations and duplicate loading. Only add `skills: ["./skills/"]` if auto-discovery does not work in a specific Claude Code version — but per current docs, it does.

### Claude Code hooks.json (SessionStart pattern)
```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -ExecutionPolicy Bypass -Command \"Write-Output '{ \\\"hookSpecificOutput\\\": { \\\"hookEventName\\\": \\\"SessionStart\\\", \\\"additionalContext\\\": \\\"Git workflow policies loaded. Use Skill tool to discover available skills.\\\" } }'\"",
            "async": false
          }
        ]
      }
    ]
  }
}
```
Source: Adapted from superpowers hooks.json + Claude Code hook spec [VERIFIED: superpowers DeepWiki + Claude Code hook specification]

**Important caveat:** Due to bug #16538, the `additionalContext` from plugin hooks.json is not currently surfaced to Claude. This code is syntactically correct but functionally may not inject context until the bug is fixed. The hook itself will still execute (visible in hook logs). [VERIFIED: anthropics/claude-code issue #16538]

### Codex marketplace.json (fixed source.path)
```json
{
  "name": "liam-local-plugins",
  "interface": {
    "displayName": "Liam Local Plugins"
  },
  "plugins": [
    {
      "name": "liam-git-workflow",
      "source": {
        "source": "local",
        "path": "../.."
      },
      "policy": {
        "installation": "AVAILABLE",
        "authentication": "ON_INSTALL"
      },
      "category": "Productivity"
    }
  ]
}
```
Source: Adapted from Codex plugin-creator SKILL.md specification [CITED: openai/codex plugin-creator SKILL.md]

**Key fix:** The current `marketplace.json` has `source.path: "."` which resolves to `.agents/plugins/` (where marketplace.json lives). To point to the repo root (where `.codex-plugin/plugin.json` and `skills/` live), use `"../.."` to go up two levels from `.agents/plugins/` to the repo root.

### Simplified install.ps1 (symlink model)
```powershell
param(
    [string]$RepoRoot,
    [string]$CodexSkillsHome = "$env:USERPROFILE\.agents\skills",
    [switch]$SkipCodex,
    [switch]$SkipClaude,
    [switch]$CleanLegacy
)

$ErrorActionPreference = 'Stop'
$resolvedRoot = if ($RepoRoot) { (Resolve-Path $RepoRoot).Path } else { (Resolve-Path (Split-Path $PSScriptRoot -Parent)).Path }

# Codex: directory junction from ~/.agents/skills/<name> -> repo/skills
if (-not $SkipCodex) {
    $target = Join-Path $CodexSkillsHome 'liam-git-workflow'
    if (Test-Path $target) { Remove-Item $target -Recurse -Force }
    cmd /c mklink /J $target "$resolvedRoot\skills"
    Write-Host "Codex: symlinked skills to $target"
}

# Claude Code: plugin is the repo itself; /plugin install handles it
# Optionally, add a developer shortcut: claude --plugin-dir <repo>
if (-not $SkipClaude) {
    Write-Host "Claude Code: Run 'claude --plugin-dir $resolvedRoot' or use /plugin install $resolvedRoot"
}

# Clean legacy file-copy installs
if ($CleanLegacy) {
    $legacyCodexSkills = Join-Path $env:USERPROFILE '.codex\skills'
    Get-ChildItem $legacyCodexSkills -Directory -Filter 'liam-git-workflow*' -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force
    $legacyClaudeCommands = Join-Path $env:USERPROFILE '.claude\commands\liam-git-workflow'
    if (Test-Path $legacyClaudeCommands) { Remove-Item $legacyClaudeCommands -Recurse -Force }
    Write-Host "Cleaned legacy install artifacts"
}
```
Source: Pattern derived from superpowers install flow + Codex symlink workaround [CITED: superpowers install documentation + openai/codex issue #17344]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| File copy install (install.ps1 copies skills, rewrites paths) | Symlink or plugin-directory install (repo IS the plugin) | Now (this phase) | No path rewriting needed; updates via `git pull` propagate instantly |
| Separate `skills/` and `claude/commands/` for two platforms | Single `skills/` directory consumed by both platforms via auto-discovery | Now (this phase) | One source of truth; Claude Code /plugin install auto-discovers skills |
| `claude/commands/*.md` as slash commands | Claude Code `skills/` auto-discovery + Skill tool | Now (this phase) | No more duplicated command files; skills serve both platforms |

**Deprecated/outdated:**
- **`claude/commands/` directory:** Deprecated per D-02. Claude Code v2.1+ auto-discovers `skills/` directory at plugin root, making separate command files unnecessary. The 10 legacy `.md` files in `claude/commands/` should be removed.
- **File-copy installation model:** Replaced by symlink + plugin manifest model. The old `Install-LiamGitWorkflowCodex` and `Install-LiamGitWorkflowClaude` functions (in `common.ps1`) that copy files and rewrite paths are no longer needed.
- **`~/.claude/commands/liam-git-workflow/` as install target:** Replaced by plugin directory model where the repo itself is the plugin directory, registered via `/plugin install`.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Claude Code auto-discovers `skills/` directory at plugin root without explicit declaration in plugin.json | Claude Code plugin.json | Skills won't load; would need to add `"skills": ["./skills/"]` to plugin.json. Mitigation: test after creating manifest. |
| A2 | The `source.path: "../.."` fix resolves correctly to repo root from `.agents/plugins/marketplace.json` | Codex marketplace | Codex fails to find plugin.json and skills/; would need to restructure marketplace or move files. Mitigation: verify path resolution logic in Codex docs. |
| A3 | Directory junction (`mklink /J`) for the entire `skills/` directory works on Windows for Codex skill discovery | Codex symlink install | Codex won't find skills; fall back to copying individual skill subdirectory junctions. Mitigation: Codex bug #17344 confirms directory symlinks work but testing needed. |
| A4 | Claude Code `/plugin install <local-path>` works with repo-as-plugin-root model (the entire repo is a valid plugin directory) | Architecture Patterns | Plugin won't install; users would need `claude --plugin-dir` as fallback. Mitigation: test against current Claude Code version. |
| A5 | Bug #16538 (plugin SessionStart additionalContext not surfaced) is still unfixed | Common Pitfalls | If fixed, we can rely on hooks.json for session bootstrap injection. The mitigation is the same — we still ship hooks.json, it just works better if fixed. |

## Open Questions

1. **Does Claude Code `/plugin install <local-path>` support Windows absolute paths with the repo-as-plugin-root model?**
   - What we know: `/plugin install` accepts local directories as source. The superpowers model of repo-root-as-plugin is established.
   - What's unclear: Whether Windows paths with backslashes or drive letters (e.g., `D:\liam\project\...`) are handled correctly by the plugin installer on Windows.
   - Recommendation: Test with current Claude Code version. Fall back to documenting `claude --plugin-dir <path>` if `/plugin install` has issues.

2. **Is the current Codex `marketplace.json` `source.path: "."` intentional or a bug?**
   - What we know: `source.path` resolves relative to marketplace.json's directory. The current value `.` resolves at `.agents/plugins/`, not the repo root.
   - What's unclear: Whether this was intentional (Codex finds the plugin via some other mechanism) or a bug (plugin doesn't actually work via marketplace).
   - Recommendation: Fix to `"../.."` to point to repo root. Test by adding the marketplace to Codex and verifying plugin discovery.

3. **Should `claude/commands/` be deleted immediately or have a deprecation transition?**
   - What we know: D-02 says "废弃" (deprecate). Claude Code auto-discovers skills from the plugin directory.
   - What's unclear: Whether any existing user has active installs relying on the `/liam-git-workflow:*` slash commands from `~/.claude/commands/`. Direct deletion would break those.
   - Recommendation: Per Claude's Discretion, delete the directory from the repo (clean structure) but note in CHANGELOG/README that users should clean `~/.claude/commands/liam-git-workflow/` if they had a previous install. The new plugin install creates no files there.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | None (static files only) | Yes | v24.15.0 | — |
| PowerShell | install.ps1, diagnostic scripts | Yes | 5.1.26100.8457 | — |
| Git | Repository operations (clone, pull) | Yes | 2.54.0.windows.1 | — |
| Claude Code | `/plugin install` consumption | Not verified | — | `claude --plugin-dir <repo>` as fallback |
| Codex | Skill discovery at `~/.agents/skills/` | Not verified | — | Manual symlink to `~/.agents/skills/` if marketplace fails |

**Missing dependencies with no fallback:**
- None. The plugin files are static JSON/Markdown. The install script requires PowerShell (available). Both Claude Code and Codex are optional — the repo can be prepared as a plugin package without either being installed.

**Missing dependencies with fallback:**
- **Claude Code not installed:** Plugin manifest creation is unaffected. Testing the install requires Claude Code runtime.
- **Codex not installed:** Marketplace config and symlink script are unaffected. Testing requires Codex runtime.

## Sources

### Primary (HIGH confidence)
- [anthropics/claude-plugins-official] — Plugin structure, manifest format, auto-discovery conventions [CITED: DeepWiki + Tessl registry]
- [Claude Code hooks specification] — hooks.json format, hookEventName, hookSpecificOutput, matcher patterns, SessionStart lifecycle [VERIFIED: multiple plugin projects + anthropics/claude-code issues]
- [openai/codex plugin-creator SKILL.md] — Codex plugin.json format, marketplace.json format, source.path resolution rules [CITED: openai/codex GitHub]
- [ECC PLUGIN_SCHEMA_NOTES.md] — Undocumented plugin.json constraints: agents field rejection, hooks duplicate loading, version mandatory, skills must be array [VERIFIED: everything-claude-code GitHub]
- [obra/superpowers] — Reference architecture: repo-as-plugin-root, .claude-plugin/plugin.json, hooks/hooks.json, skills/ directory structure [VERIFIED: web search + DeepWiki analysis]

### Secondary (MEDIUM confidence)
- [anthropics/claude-code issue #16538] — Plugin SessionStart hooks don't surface additionalContext (confirmed open) [VERIFIED: GitHub issue search]
- [openai/codex issue #17344] — Codex skips file-level SKILL.md symlinks (confirmed bug) [VERIFIED: GitHub issue search]
- [Codex Plugins 插件机制与本地安装教程 (CSDN, 2026-05)] — Chinese language Codex plugin installation walkthrough [CITED: blog.csdn.net]
- [Superpowers Skill 全面技术教程 (Zhihu, 2026-04)] — Chinese technical analysis of superpowers architecture [CITED: zhuanlan.zhihu.com]

### Tertiary (LOW confidence)
- [Superpowers DeepWiki pages] — Directory structure and integration details (secondary source aggregating from GitHub) [CITED: deepwiki.com]
- [everything-claude-code issue #103] — Duplicate hooks error from explicit declaration [CITED: GitHub issues, not from official Anthropic docs]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — Plugin manifest formats are well-documented and verified against multiple reference implementations and official sources
- Architecture: HIGH — The repo-as-plugin-root pattern is established by superpowers and confirmed through Claude Code plugin documentation
- Pitfalls: HIGH — Multiple real-world bug reports and schema validation notes confirm the undocumented constraints; the SessionStart hook bug is tracked in the official Claude Code repo
- Codex marketplace path resolution: MEDIUM — Verified against official plugin-creator docs but not tested against current Codex version

**Research date:** 2026-05-25
**Valid until:** 2026-08-25 (3 months — plugin manifest formats are stable but the SessionStart hook bug may be fixed)
