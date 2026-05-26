---
phase: 04-superpowers-codex-claude-code
reviewed: 2026-05-26T00:00:00Z
depth: standard
files_reviewed: 11
files_reviewed_list:
  - .agents/plugins/marketplace.json
  - .claude-plugin/plugin.json
  - .codex-plugin/plugin.json
  - CHANGELOG.md
  - README.md
  - VERSION
  - hooks/hooks.json
  - scripts/common.ps1
  - scripts/install.ps1
  - scripts/link_codex_global_skills.ps1
  - scripts/update.ps1
findings:
  critical: 0
  warning: 2
  info: 2
  total: 4
status: issues_found
---

# Phase 04: Code Review Report

**Reviewed:** 2026-05-26
**Depth:** standard
**Files Reviewed:** 11
**Status:** issues_found (2 warnings, 2 info; 0 critical)

## Summary

Reviewed 11 files across the plugin packaging layer for the Liam Git Workflow project. The codebase is well-structured, with clean PowerShell scripting, proper error handling via `$ErrorActionPreference = "Stop"`, and clear separation of concerns between install/update/linking scripts.

Two warnings were identified: non-portable absolute file paths in README.md links, and a JSON-in-PowerShell quote escaping bug in `hooks/hooks.json` that would cause the SessionStart hook command to produce garbled arguments. Two informational items cover version duplication risk and suppressed stderr during cleanup.

## Warnings

### WR-01: README.md uses non-portable absolute file paths in markdown links

**File:** `README.md:211-215`
**Issue:** All five links under the "规则来源" section use absolute Windows file paths rooted at `D:/liam/project/others/20260511_liam_git_workflow/references/...`. These links are non-portable -- they will not resolve correctly on any other machine, in any other checkout location, or in most markdown renderers. The links reference files that are sibling paths relative to README.md itself (`references/policy.md`, etc.).
**Fix:** Replace absolute paths with relative paths:

```markdown
## 规则来源

- [policy.md](references/policy.md): 核心工作流策略
- [branch-matrix.md](references/branch-matrix.md): 分支决策规则
- [commit-rules.md](references/commit-rules.md): 提交规范
- [pr-rules.md](references/pr-rules.md): PR 与合并规则
- [scenarios.md](references/scenarios.md): 常见场景示例
```

### WR-02: hooks.json SessionStart command has broken JSON-in-PowerShell quote escaping

**File:** `hooks/hooks.json:9`
**Issue:** The PowerShell command embeds a JSON string literal inside a `-Command` double-quoted argument. The inner JSON double quotes (`"hookSpecificOutput"`, `"hookEventName"`, etc.) are JSON-escaped once (`\"`) in the hooks.json file, reducing to plain `"` characters in the parsed string value. When the resulting command string is executed, these inner `"` characters prematurely terminate the `-Command` argument, producing a broken PowerShell command. The command output will be garbled and the hook will not produce the expected JSON.
**Fix:** The cleanest solution is to avoid manual JSON construction inside PowerShell and instead use `ConvertTo-Json` to generate the output programmatically, eliminating the nested-quoting problem entirely:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup|clear|compact",
        "hooks": [
          {
            "type": "command",
            "command": "powershell -NoProfile -ExecutionPolicy Bypass -Command \"$o = @{ hookSpecificOutput = @{ hookEventName = 'SessionStart'; additionalContext = 'Git workflow policies loaded. Use Skill tool to discover available skills.' } }; $o | ConvertTo-Json -Compress\"",
            "async": false
          }
        ]
      }
    ]
  }
}
```

Alternatively, if the literal-JSON approach is preferred, the inner double quotes need to survive JSON parsing as `\"` characters, which requires `\\\"` escaping in the JSON source:

```
\"Write-Output '{ \\\"hookSpecificOutput\\\": { \\\"hookEventName\\\": \\\"SessionStart\\\", \\\"additionalContext\\\": \\\"Git workflow policies loaded. Use Skill tool to discover available skills.\\\" } }'\"
```

## Info

### IN-01: Version string duplicated across three files

**Files:** `VERSION:1`, `.claude-plugin/plugin.json:3`, `.codex-plugin/plugin.json:3`
**Issue:** The version number `0.3.0` appears in three separate files that must all be kept in sync manually. If a future release updates `VERSION` but forgets one of the `plugin.json` files, version drift will occur.
**Fix:** Consider having the build/release process read `VERSION` as the single source of truth and inject it into both plugin manifests. Or add a simple CI verification step that asserts all three values match. The `scripts/common.ps1` already has a `Get-LiamGitWorkflowVersion` function that reads the VERSION file -- the install script could emit a warning if `plugin.json` versions don't match.

### IN-02: install.ps1 suppresses stderr during legacy cleanup

**File:** `scripts/install.ps1:32`
**Issue:** `cmd /c rmdir "$codexTarget" 2>$null` redirects stderr to null when attempting to remove the existing Codex skills junction. While the subsequent `Remove-Item` call on line 34 serves as a fallback, silently discarding stderr means that if `rmdir` fails for a non-obvious reason (permissions, filesystem corruption, path encoding), the root cause is hidden from the user.
**Fix:** Capture stderr and include it in the error message if the fallback `Remove-Item` also fails, or write stderr to `Write-Verbose` instead of discarding it entirely:

```powershell
$rmdirErr = cmd /c rmdir "$codexTarget" 2>&1
if ($rmdirErr -and (Test-Path -LiteralPath $codexTarget)) {
    Write-Warning "rmdir produced output: $rmdirErr"
    Remove-Item -LiteralPath $codexTarget -Recurse -Force
}
```

---

_Reviewed: 2026-05-26_
_Reviewer: Claude (gsd-code-reviewer)_
_Depth: standard_
