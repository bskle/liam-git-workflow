---
phase: 02-diagnostic-core
plan: 01
subsystem: diagnostic-script
tags:
  - powershell
  - git-diagnostics
  - structured-output
  - network-probing
  - signal-mapping
dependency-graph:
  provides:
    - "scripts/diagnose_git_remote.ps1: Git 远程诊断核心脚本（五层诊断 + 信号映射 + 结构化 JSON 输出）"
  requires: []
  affects:
    - "Phase 03: 工作流集成（主 Agent 将通过此脚本获取诊断结论并执行修复）"
tech-stack:
  added:
    - "PowerShell 5.1 (Windows 11 内置)"
    - "Test-NetConnection、Resolve-DnsName、curl.exe、ssh.exe（均为 Windows 11 内置）"
  patterns:
    - "乐观证据收集（五层全部执行，不因早期发现故障而中断）"
    - "声明式信号到原因映射表（21 条规则，按置信度排序）"
    - "结构化 JSON 输出契约（8 个必填字段）"
    - "Invoke-DiagnosticCommand 安全包装器（临时 Continue 模式 + LASTEXITCODE 检查）"
key-files:
  created:
    - "scripts/diagnose_git_remote.ps1"
  modified: []
decisions:
  - "$ErrorActionPreference = 'Continue'（脚本级）：禁止 Stop 模式，防止 PS 5.1 2>&1 bug"
  - "param() 块必须在 Set-StrictMode 之前：PS 5.1 解析器要求"
  - "UTF-8 with BOM 编码：PS 5.1 无 BOM 时无法正确解析中文字符"
  - "SSH 检查前必须 TCP 22 预检：防止 ssh -T 挂起"
  - "DNS 解析双通道：Resolve-DnsName 优先，[System.Net.Dns]::GetHostEntry() 回退"
  - "代理检测双源：注册表 HKCU Internet Settings + 环境变量 HTTP_PROXY/HTTPS_PROXY"
  - "ConvertTo-Json -Depth 4：防止 PS 5.1 默认 depth 2 截断嵌套数组"
  - "human_interaction_required 仅 4 种 CLI 不可观测场景为 true"
metrics:
  duration: ~18 minutes
  completed_date: 2026-05-25
---

# Phase 2 Plan 1: Git 远程诊断核心脚本实现 Summary

**One-liner:** 实现自包含 PowerShell 5.1 诊断脚本，通过五层乐观收集+信号映射引擎产出结构化 JSON 供主 Agent 消费

## Completion Status

**Status:** COMPLETE

### Tasks Completed

| # | Task | Commit | Files |
|---|------|--------|-------|
| 1 | 脚本骨架 + 参数处理 + 辅助函数 + 诊断层 1-3 | `9700a2f` | `scripts/diagnose_git_remote.ps1` (创建) |
| 2 | 诊断层 4-5 + 信号映射引擎 + 输出构建器 + 主流程编排 | `7bcf6b7` | `scripts/diagnose_git_remote.ps1` (追加) |

## What Was Built

**`scripts/diagnose_git_remote.ps1`** (约 700 行) — 自包含 Git 远程操作故障诊断脚本，无外部模块依赖：

### 架构组成

1. **参数接口**：`-RepoPath`, `-RemoteName`, `-FailedCommand`, `-Stderr`（均为可选有默认值）
2. **安全包装器**：`Invoke-DiagnosticCommand`（临时 Continue 模式 + LASTEXITCODE 检查）+ `Invoke-GitCommand`（Git 专用）
3. **五层诊断**（乐观收集模式，全部执行）：
   - Layer 1 `Test-LocalRepositoryState`：detached HEAD、merge/rebase、冲突、upstream、工作区状态
   - Layer 2 `Test-RemoteTarget`：remote URL 验证、格式检查、`git ls-remote --heads`
   - Layer 3 `Test-Authentication`：HTTPS/SSH 判断、凭据助手、SSH 前 TCP 22 预检、stderr 签名匹配
   - Layer 4 `Test-NetworkPath`：Git 代理、环境代理、注册表系统代理、DNS 解析（含 .NET 回退）、TCP 443、curl HTTPS 探测
   - Layer 5 `Test-RepositoryPolicy`：stderr 模式匹配（受保护分支、非 fast-forward、仓库不存在、组织策略）
4. **信号映射**：`Resolve-RootCause` — 21 条声明式规则，high/medium 置信度排序
5. **输出构建**：`Build-StructuredOutput` — `[ordered]@{}` + `ConvertTo-Json -Depth 4`

### 输出契约（8 字段）

| 字段 | 类型 | 状态 |
|------|------|------|
| `problem_category` | string | 与 references/remote-diagnostics.md 故障分类对齐 |
| `evidence` | string[] | 诊断过程收集的所有信号和 CLI 输出 |
| `likely_cause` | string | 信号映射匹配度最高的可能原因 |
| `confidence` | enum: high/medium/low | 基于证据充分性的置信度评估 |
| `actions_taken` | string[] | 已执行的诊断步骤（按顺序） |
| `recommended_next_action` | string | 可执行的下一步修复操作 |
| `human_interaction_required` | boolean | 仅在 CLI 不可观测时设为 true |
| `human_action_detail` | string / null | 三段式用户提示（仅 true 时） |

### human_interaction_required 触发场景

仅以下 4 种 CLI 不可观测场景设为 `$true`：
- 仓库策略拒绝（需浏览器检查分支保护设置）
- 仓库不存在（需浏览器确认仓库状态）
- 授权不足（需浏览器检查 Token 权限和 SSO 状态）
- TLS/SSL 错误（需 certmgr.msc 检查证书存储）

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Set-StrictMode 必须在 param() 之后**
- **Found during:** Task 1
- **Issue:** PowerShell 5.1 解析器不允许在 `param()` 块之前放置任何可执行语句（包括 `Set-StrictMode -Version Latest`）
- **Fix:** 调整顺序为 `param()` → `Set-StrictMode -Version Latest` → `$ErrorActionPreference = 'Continue'`
- **Files modified:** `scripts/diagnose_git_remote.ps1`
- **Commit:** `9700a2f`

**2. [Rule 3 - Blocking] UTF-8 BOM 编码要求**
- **Found during:** Task 1
- **Issue:** PowerShell 5.1 无 BOM 的 UTF-8 文件在解析时无法正确处理中文字符，导致语法错误
- **Fix:** 使用 Node.js 为文件添加 EF BB BF (UTF-8 BOM) 前缀，确保 PowerShell 解析器正确识别中文注释和字符串字面量
- **Files modified:** `scripts/diagnose_git_remote.ps1`
- **Commit:** `9700a2f`

**3. [Rule 1 - Bug] TCP 443.*False 模式过于宽泛**
- **Found during:** Task 2 运行时测试
- **Issue:** 信号映射表中的 `TCP 443.*False` 正则匹配了证据行中的 "PingSucceeded = False"（当 TCP 连接实际成功但 ICMP ping 被阻止时），导致健康仓库被误判为"连接超时/拒绝"
- **Fix:** 将模式改为 `TcpTestSucceeded = False`，精确匹配 TCP 连接测试结果，避免平级字段 False 导致的误匹配
- **Files modified:** `scripts/diagnose_git_remote.ps1` (line 589)
- **Commit:** `7bcf6b7`

## Verification Summary

### Static Validation

| Criterion | Result |
|-----------|--------|
| PowerShell 语法检查（零解析错误） | PASS |
| `$ErrorActionPreference = 'Stop'` 全脚本禁止 | PASS (0 occurrences) |
| 10 个必填函数全部存在 | PASS |
| `ConvertTo-Json -Depth 4` 存在 | PASS (3 uses) |
| 信号映射表 >= 15 条 | PASS (21 条) |
| 所有外部命令通过 Invoke-DiagnosticCommand 包装 | PASS (13 calls) |

### Runtime Validation

| Test | Result |
|------|--------|
| Git 仓库中运行 → 有效 JSON 输出 | PASS |
| JSON 包含全部 8 个必填字段 | PASS |
| `evidence` 和 `actions_taken` 为数组类型 | PASS |
| `human_interaction_required` 为布尔类型 | PASS |
| 非 Git 仓库目录优雅降级（`problem_category = "本地状态阻塞"`） | PASS |
| `human_action_detail` 在非人工交互时为 null | PASS |

## Known Stubs

None - all functions are fully implemented with complete logic paths.

## Threat Flags

None - all threat mitigations from the plan's threat model are implemented:
- T-02-01 (credentials in evidence): Script only records credential helper name, not content
- T-02-02 (path traversal): Uses `Resolve-Path` + `Test-Path -LiteralPath`
- T-02-03 (command injection): Only static `-match` patterns on `$Stderr`, no `Invoke-Expression`
- T-02-04 (stdout/stderr separation): JSON to stdout via `Write-Output`, diagnostic data internal
- T-02-05 (SSH hang): `ConnectTimeout=5` + TCP 22 pre-check before SSH
- T-02-06 (registry privilege): HKCU only with graceful degradation on access denied
