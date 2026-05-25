# Phase 02: Diagnostic Core - Research

**Researched:** 2026-05-25
**Domain:** PowerShell 5.1 scripting, Git remote diagnostics, network probing, structured CLI output
**Confidence:** HIGH

## Summary

Phase 2 实现诊断核心脚本 `scripts/diagnose_git_remote.ps1`，覆盖五层诊断（本地状态 -> 远程目标 -> 认证授权 -> 网络路径 -> 仓库策略），产出结构化 JSON 输出给主 Agent 消费，最小化人工交互。

核心脚本是一个纯 PowerShell 5.1 脚本，无外部模块依赖（所有探测工具均为 Windows 11 内置：Test-NetConnection、Resolve-DnsName、curl.exe、nslookup）。脚本需要在内聚性和可维护性之间取得平衡：五层诊断各有独立函数，但共享一个统一的输出构建器。关键架构决策是使用"乐观收集"模式——即使在早期层发现故障，也继续收集所有层的证据，确保最完整的诊断视图。

**Primary recommendation:** 使用 `$ErrorActionPreference = 'Continue'`（而非项目其他脚本使用的 `Stop`）作为脚本级默认值，以便每个诊断步骤独立失败而不中断整体流程。在每个外部命令后通过 `$LASTEXITCODE` 检查退出码。使用 `[ordered]@{}` 构建结构化输出对象，通过 `ConvertTo-Json -Depth 4` 在脚本末尾统一输出。

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Local state detection (branch, merge, conflicts) | PowerShell Script | — | 直接检查 `.git` 目录和 `git status` 输出，属于 CLI 本地操作 |
| Remote target validation (URL parsing, upstream check) | PowerShell Script | — | 解析 `git remote -v` 和 `git branch -vv` 输出，纯 CLI 操作 |
| Authentication inspection (credential helper, SSH check) | PowerShell Script | — | 读取 git config、检查 SSH agent/keys，均为本地 CLI 可观测 |
| Network probing (DNS, TCP, HTTPS, proxy) | PowerShell Script | — | Test-NetConnection、Resolve-DnsName、curl.exe 均为本地探测工具 |
| Repository policy detection (error pattern matching) | PowerShell Script | — | 对 stderr 输出做模式匹配，CLI 可完成 |
| Structured output generation | PowerShell Script | — | ConvertTo-Json 生成 JSON，主 Agent 消费 |
| Human interaction boundary decisions | PowerShell Script | Policy (SKILL.md) | 脚本判断是否需要人工交互，SKILL.md 定义交互格式 |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| PowerShell | 5.1.26100 | Script runtime | Windows 11 内置，项目约束 [VERIFIED: CLAUDE.md 运行时约束] |
| Git | 2.54.0 | Git state queries | 项目要求 Git 2.40+ [VERIFIED: CLAUDE.md] |
| Test-NetConnection (NetTCPIP module) | built-in | TCP port probe | PowerShell 5.1 内置模块，无额外安装 [VERIFIED: 本机 Get-Command] |
| Resolve-DnsName (DnsClient module) | built-in | DNS resolution | PowerShell 5.1 内置模块，比 nslookup 输出更结构化 [VERIFIED: 本机 Get-Command] |
| curl.exe | built-in (Win 10 17063+) | HTTPS reachability probe | Windows 11 内置真实 curl（非 PowerShell alias），用于最小 HTTP 探测 [VERIFIED: 本机 Get-Command] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| nslookup.exe | built-in | DNS resolution fallback | 当 Resolve-DnsName 不可用时的回退方案（实际不应出现，但保留） |
| [System.Net.Dns]::GetHostEntry() | .NET Framework | DNS resolution universal fallback | 在所有 PowerShell 版本中可用，不需要任何模块 |
| [System.Net.Sockets.TcpClient] | .NET Framework | 细粒度 TCP 诊断 | 当需要区分"连接超时"和"连接拒绝"时使用（Test-NetConnection 不区分两者） |
| Invoke-WebRequest | built-in | HTTP/HTTPS 探测回退 | 当 curl.exe 不可用时的回退方案 |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Test-NetConnection | Test-Connection -TcpPort (PS 7+) | PS 5.1 不支持 Test-Connection 的 -TcpPort 参数 |
| Resolve-DnsName | nslookup 文本解析 | nslookup 输出不稳定，需解析文本，出错率高 |
| curl.exe | Invoke-WebRequest | Invoke-WebRequest 受系统代理配置影响更大，可能导致诊断误判 |

**Installation:** 无需额外安装。脚本仅依赖 Windows 11 内置工具和 Git。
```bash
# 验证依赖（在目标 Windows 11 系统上运行）
powershell -Command "Get-Command Test-NetConnection, Resolve-DnsName, curl.exe, nslookup, git"
```

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│                    diagnose_git_remote.ps1                              │
│                                                                         │
│  Entry: param(-RepoPath, -RemoteName, -FailedCommand, -Stderr)          │
│                                                                         │
│  ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌──────────┐    ┌─────┤
│  │ Layer 1  │───>│ Layer 2  │───>│ Layer 3  │───>│ Layer 4  │───>│ L5  │
│  │ Local    │    │ Remote   │    │ Auth     │    │ Network  │    │ Pol │
│  │ State    │    │ Target   │    │          │    │ Path     │    │     │
│  └────┬─────┘    └────┬─────┘    └────┬─────┘    └────┬─────┘    └──┬──┘
│       │               │               │               │              │
│       │  git status   │  git remote   │  git config   │  Test-Net    │  pattern
│       │  git branch   │  git branch   │  ssh -T       │  Resolve-    │  match on
│       │  .git/ check  │  URL parse    │  cred helper  │  DnsName     │  stderr
│       │               │               │               │  curl.exe    │
│       │               │               │               │  proxy reg   │
│       │               │               │               │  ls-remote   │
│       └───────┬───────┴───────┬───────┴───────┬───────┴──────┬───────┘
│               │               │               │              │
│               └───────────────┴───────────────┴──────────────┘
│                                       │
│                               Evidence Accumulator
│                          (collects all findings, never aborts)
│                                       │
│                          ┌────────────▼────────────┐
│                          │   Build-StructuredOutput │
│                          │                           │
│                          │  problem_category         │
│                          │  evidence[]               │
│                          │  likely_cause             │──> ConvertTo-Json
│                          │  confidence               │    (stdout)
│                          │  actions_taken[]          │
│                          │  recommended_next_action  │
│                          │  human_interaction_required│
│                          │  human_action_detail      │
│                          └───────────────────────────┘
│                                       │
│                          ┌────────────▼────────────┐
│                          │    Signal-to-Cause       │
│                          │    Mapping Engine        │
│                          │  (pattern match evidence │
│                          │   → best-fit category,   │
│                          │   cause, confidence)     │
│                          └──────────────────────────┘
└─────────────────────────────────────────────────────────────────────────┘
                                   │
                     JSON stdout   │   stderr (diagnostic log)
                                   │
                          ┌────────▼────────┐
                          │   Main Agent     │
                          │   (Claude Code)  │
                          │                  │
                          │  Reads JSON →    │
                          │  Acts on         │
                          │  recommendation  │
                          └──────────────────┘
```

### Recommended Project Structure
```
scripts/
├── diagnose_git_remote.ps1    # Phase 2 deliverable — diagnostic core script
├── common.ps1                 # Existing — NOT sourced by diagnostic script
├── install.ps1                # Existing
├── update.ps1                 # Existing
├── validate_commit_message.ps1 # Existing
└── ...
```

The diagnostic script is self-contained. It does NOT source `common.ps1` because:
- `common.ps1` functions (Resolve-LiamGitWorkflowRepoRoot etc.) are designed for the project's own installation workflow
- The diagnostic script operates on arbitrary git repos, not the project repo
- Self-containment simplifies deployment (the script is a single file that can be copied anywhere)

### Pattern 1: Optimistic Evidence Collection

**What:** Every diagnostic layer executes fully, regardless of failures found in earlier layers. Evidence accumulates in a shared collection. The final output reflects ALL findings, not just the first problem found.

**When to use:** Throughout the entire script — this is the core execution philosophy.

**Example:**
```powershell
# Pseudo-code for the diagnostic loop
$evidence = @()
$actionsTaken = @()

# Layer 1 always runs
$layer1Result = Test-LocalRepositoryState -RepoPath $RepoPath
$evidence += $layer1Result.Evidence
$actionsTaken += $layer1Result.Actions

# Layer 2 always runs (even if Layer 1 found problems)
$layer2Result = Test-RemoteTarget -RepoPath $RepoPath -RemoteName $RemoteName
$evidence += $layer2Result.Evidence
$actionsTaken += $layer2Result.Actions

# ... and so on through all 5 layers

# Final classification uses ALL evidence
$output = Build-StructuredOutput -Evidence $evidence -Actions $actionsTaken
```

### Pattern 2: External Command Safe Wrapper

**What:** Wrapper function that runs an external command, captures stdout/stderr/exit code separately, and NEVER terminates the script.

**When to use:** Every call to `git`, `ssh`, `curl`, `nslookup`, or any external executable.

**Example:**
```powershell
# Source: Web research verified — $ErrorActionPreference does NOT apply to
# external commands in PS 5.1. The 2> redirection with Stop causes a bug
# where any stderr output terminates the script.
function Invoke-DiagnosticCommand {
    param(
        [string]$CommandName,
        [scriptblock]$ScriptBlock
    )
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'  # Critical: prevent 2> bug

    $output = $null
    $stderr = $null
    try {
        $output = & $ScriptBlock 2>&1 | Out-String
        $exitCode = $LASTEXITCODE
    } catch {
        $stderr = $_.Exception.Message
        $exitCode = -1
    }

    $ErrorActionPreference = $prevEAP
    return @{
        Output   = $output
        ExitCode = $exitCode
        Error    = $stderr
    }
}
```

### Pattern 3: Signal-to-Cause Mapping Engine

**What:** After all evidence is collected, a deterministic matching function maps observed error signals to the best-fit problem category, cause description, and confidence level. The mapping table is embedded directly in the script (derived from `references/remote-diagnostics.md`).

**When to use:** At the end of the diagnostic pipeline, before building the final output object.

**Example:**
```powershell
function Resolve-RootCause {
    param([string[]]$Evidence)
    # Matching priority: stderr error messages first (highest confidence)
    # then network probe failures (medium confidence)
    # then ambiguous signals (low confidence)
    $patterns = @(
        @{ Pattern = 'Could not resolve host'; Category = 'DNS 解析失败'; Confidence = 'high' },
        @{ Pattern = 'Authentication failed'; Category = '认证失败'; Confidence = 'high' },
        @{ Pattern = 'protected branch'; Category = '仓库策略拒绝'; Confidence = 'high' },
        # ... more patterns from reference knowledge base
    )
    foreach ($p in $patterns) {
        if ($Evidence -match $p.Pattern) {
            return $p
        }
    }
    return @{ Category = '未知'; Confidence = 'low' }
}
```

### Pattern 4: Structured Output Builder

**What:** A single function that assembles all collected evidence, actions, and classification into the 8-field output contract object, then serializes to JSON.

**When to use:** At the very end of the script, once.

**Example:**
```powershell
function Build-StructuredOutput {
    param(
        [string]$ProblemCategory,
        [string[]]$Evidence,
        [string]$LikelyCause,
        [string]$Confidence,
        [string[]]$ActionsTaken,
        [string]$RecommendedNextAction,
        [bool]$HumanInteractionRequired,
        [string]$HumanActionDetail
    )
    $result = [ordered]@{
        problem_category            = $ProblemCategory
        evidence                    = [array]$Evidence
        likely_cause                = $LikelyCause
        confidence                  = $Confidence
        actions_taken               = [array]$ActionsTaken
        recommended_next_action     = $RecommendedNextAction
        human_interaction_required  = $HumanInteractionRequired
        human_action_detail         = $HumanActionDetail
    }
    return $result | ConvertTo-Json -Depth 4 -Compress
}
```

### Anti-Patterns to Avoid

- **Setting `$ErrorActionPreference = 'Stop'`:** 会导致脚本在第一个外部命令失败时就终止，无法完成全部诊断层的检查。诊断脚本的价值在于收集完整证据，而不是在第一个问题上就停止。 [VERIFIED: Web search — PS 5.1 $ErrorActionPreference does not apply to external commands but causes 2> redirection bugs]
- **Stopping at the first signal match:** 发现一个原因就停止会掩盖复合故障。例如，本地可能有未推送的提交（Layer 1），同时网络也有 DNS 问题（Layer 4）。必须收集所有层的所有信号后再综合判断。
- **Using `Write-Error` for diagnostic findings:** `Write-Error` 写入错误流，干扰 JSON stdout 输出。诊断发现应该记录在 evidence 数组中，而非写入 stderr。
- **Parsing `nslookup` output text:** 文本解析不稳定（跨 Windows 版本输出格式不同）。始终优先使用 `Resolve-DnsName`，它以对象形式返回结果。 [VERIFIED: Web search — Resolve-DnsName official docs]
- **Using `ConvertTo-Json` without explicit `-Depth`:** PS 5.1 默认深度仅为 2，嵌套超过 2 层的对象会被截断（显示为字符串 `"System.Object[]"`）。evidence 和 actions_taken 数组在深度 2 时会出问题。必须使用 `-Depth 4` 或更高。 [VERIFIED: 本机测试]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| TCP reachability check | Raw TCP socket code | `Test-NetConnection -Port 443` | 处理 DNS 解析、ICMP 测试、TCP 握手、路由跟踪的完整诊断链。手写 Socket 需要处理异步超时、异常分类。 |
| DNS resolution | `nslookup` text parsing | `Resolve-DnsName <host>` | 返回结构化对象（IPAddress、TTL、Server），无需脆弱的正则解析。不可用时回退到 `[System.Net.Dns]::GetHostEntry()`。 |
| JSON output construction | 字符串拼接 JSON | `[ordered]@{}` + `ConvertTo-Json -Depth 4` | 处理转义、嵌套、Unicode、数组序列化。手写 JSON 极易在路径包含 `\` 或双引号时出错。 |
| HTTPS connectivity probe | Sockets or `Invoke-RestMethod` | `curl.exe -I https://<host>` | Windows 11 内置真实 curl，输出标准化，不受 PowerShell WebRequest 代理继承行为影响，诊断更准确。 |
| Proxy detection | 环境变量猜测 | Registry read `HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings` + `$env:HTTP_PROXY` | Windows 系统代理配置存在注册表，不是环境变量。需同时检查两处才能完整覆盖。 |
| Signal-to-cause mapping | 启发式 if-else 链 | 声明式模式表 + 遍历匹配 | 模式表可维护、可扩展、与 reference knowledge base 保持同步。 |

**Key insight:** PowerShell 5.1 内置的网络诊断工具链（Test-NetConnection + Resolve-DnsName + curl.exe）已经覆盖了本脚本所需的全部网络探测能力。不需要任何第三方模块或自定义网络代码。

## Runtime State Inventory

> This phase is a greenfield script creation. No runtime state to migrate. Omit section.

**Omitted** -- Phase 2 creates a new script, does not rename/refactor/migrate any existing runtime state.

## Common Pitfalls

### Pitfall 1: `$ErrorActionPreference = 'Stop'` 导致 `2>` 重定向 Bug

**What goes wrong:** 当设置 `$ErrorActionPreference = 'Stop'` 并使用 `2>&1` 重定向外部命令的 stderr 时，即使命令成功退出（exit code 0），任何 stderr 输出都会触发脚本级终止错误。这在 PowerShell 5.1 中是已知 bug（GitHub issue #4002），在 PowerShell 7.2+ 中才修复。

**Why it happens:** PowerShell 5.1 的 `2>` 重定向将 stderr 路由到 ErrorRecord 流，而 `$ErrorActionPreference = 'Stop'` 会将其提升为终止错误。

**How to avoid:** 在调用外部命令前临时设置 `$ErrorActionPreference = 'Continue'`，执行后恢复。始终通过 `$LASTEXITCODE` 检查退出码，而非依赖错误处理机制。

**Warning signs:** 脚本在 `git status` 调用时意外终止（`git status` 正常无错误，但 `2>&1` 会路由空 stderr，某些情况下也会触发）。

### Pitfall 2: `ConvertTo-Json` 深度截断

**What goes wrong:** 在 PowerShell 5.1 中，嵌套超过 2 层的对象/数组会被截断为字符串字面量（如 `"System.Object[]"` 或 `"System.Collections.Hashtable"`），导致输出的 JSON 无法被主 Agent 正确解析。

**Why it happens:** PS 5.1 的 `ConvertTo-Json` 默认 `-Depth 2`。当 evidence 或 actions_taken 数组包含含有子属性的对象时，超过深度 2 的内容会被截断。

**How to avoid:** 始终使用 `ConvertTo-Json -Depth 4`（或更高，`-Depth 10` 为保守选择）。

**Warning signs:** 输出的 JSON 中包含 `"System.Object[]"` 字符串（而非实际数组内容）。

### Pitfall 3: `Resolve-DnsName` 在非 Windows 环境中不可用

**What goes wrong:** `Resolve-DnsName` 是 DnsClient 模块的一部分，仅在 Windows PowerShell 中可用。如果脚本意外在 PowerShell 7 (Core) 的 Windows 环境下运行，该 cmdlet 可能不在默认模块路径中。

**Why it happens:** `Resolve-DnsName` 绑定在 Windows DNS Client 服务上，不是跨平台的。

**How to avoid:** 脚本顶部添加可用性检查，如果不支持则自动回退到 `[System.Net.Dns]::GetHostEntry()`（在所有 PS 版本和所有平台中可用）。

**Warning signs:** `Get-Command Resolve-DnsName` 返回空。

### Pitfall 4: 诊断脚本在非 Git 仓库中运行时崩溃

**What goes wrong:** 如果用户在非 Git 仓库目录中调用脚本，`git` 命令会失败。脚本必须优雅处理这种情况（本身就是诊断场景的第一层检查），而非直接崩溃。

**Why it happens:** 开发者可能在测试时使用仓库目录，忽略边缘情况。

**How to avoid:** 脚本的第一个检查是 `git rev-parse --git-dir`。如果失败，立即将其识别为"本地状态阻塞"问题并输出完整诊断结论，标记 `problem_category = "本地状态阻塞"`，`likely_cause = "当前目录不是 Git 仓库"`。

**Warning signs:** `fatal: not a git repository` 未被脚本优雅处理，导致混乱的后续错误。

### Pitfall 5: 认证层检查中 `ssh -T git@github.com` 永久挂起

**What goes wrong:** 如果 SSH 端口 22 被防火墙阻止（drop 而非 reject），`ssh -T` 会挂起直到 TCP 超时（默认约 60 秒）。

**Why it happens:** SSH 客户端的默认 ConnectTimeout 较长，且 `ssh -T` 没有简单方式设置超时。

**How to avoid:** 在 SSH 检查前先执行 TCP 22 探测（`Test-NetConnection <host> -Port 22`）。如果 TCP 22 不可达，跳过 SSH 检查并记录原因。或者使用 `ssh -o ConnectTimeout=5 -T git@github.com`。

**Warning signs:** 脚本在认证检查阶段"卡住"60 秒无输出。

## Code Examples

Verified patterns from official sources and existing project scripts:

### External command execution with safe error capture
```powershell
# Source: Web research verified — PS 5.1 native command error handling pattern
# This pattern is adapted to avoid the $ErrorActionPreference + 2> bug
function Invoke-GitCommand {
    param(
        [string]$RepoPath,
        [string[]]$Arguments
    )
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'

    $stdout = $null
    $exitCode = 0

    try {
        $stdout = & git -C $RepoPath @Arguments 2>&1 | Out-String
        $exitCode = $LASTEXITCODE
    } catch {
        $exitCode = $LASTEXITCODE
        if ($exitCode -eq 0) { $exitCode = 1 }
    }

    $ErrorActionPreference = $prevEAP
    return @{
        Stdout   = $stdout.Trim()
        ExitCode = $exitCode
    }
}
```

### TCP port probe
```powershell
# Source: Microsoft TechCommunity + verified on this system
# Test-NetConnection is available via NetTCPIP module on PS 5.1
$result = Test-NetConnection -ComputerName 'github.com' -Port 443 `
    -InformationLevel Detailed -WarningAction SilentlyContinue
# Key fields: $result.TcpTestSucceeded (bool), $result.RemoteAddress (IP),
# $result.PingSucceeded (bool), $result.NameResolutionSucceeded (bool)
```

### DNS resolution
```powershell
# Source: Microsoft official docs + verified on this system
# Resolve-DnsName returns structured objects; fallback to .NET if unavailable
try {
    $dns = Resolve-DnsName -Name $hostname -Type A -ErrorAction Stop `
        -QuickTimeout
    $ipAddresses = $dns | Where-Object { $_.QueryType -eq 'A' } |
        Select-Object -ExpandProperty IPAddress
} catch {
    # Universal fallback — works in all PS versions
    try {
        $entry = [System.Net.Dns]::GetHostEntry($hostname)
        $ipAddresses = $entry.AddressList |
            Where-Object { $_.AddressFamily -eq 'InterNetwork' } |
            Select-Object -ExpandProperty IPAddressToString
    } catch {
        $ipAddresses = @()
    }
}
```

### Windows proxy detection
```powershell
# Source: Microsoft TechNet blogs + verified on this system
# Two sources: registry (system IE/WinINET proxy) + environment variables
$proxyInfo = [ordered]@{
    system_proxy_enabled = $false
    system_proxy_server  = $null
    env_http_proxy       = $env:HTTP_PROXY
    env_https_proxy      = $env:HTTPS_PROXY
}
try {
    $reg = Get-ItemProperty `
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings'
    $proxyInfo.system_proxy_enabled = ($reg.ProxyEnable -eq 1)
    $proxyInfo.system_proxy_server  = $reg.ProxyServer
} catch {
    # Registry key not accessible — non-fatal
}
```

### Structured JSON output
```powershell
# Source: Verified pattern on this system — [ordered] preserves key order
# ConvertTo-Json -Depth 4 prevents nested object truncation
$output = [ordered]@{
    problem_category            = "DNS 解析失败"
    evidence                    = @(
        "nslookup github.com 返回 NXDOMAIN",
        "Test-NetConnection github.com -Port 443: NameResolutionSucceeded = False"
    )
    likely_cause                = "DNS 服务器无法解析 github.com，可能由于企业 DNS 过滤"
    confidence                  = "high"
    actions_taken               = @(
        "git branch --show-current → feature/test",
        "git remote -v → origin https://github.com/user/repo.git",
        "nslookup github.com → NXDOMAIN",
        "Test-NetConnection github.com -Port 443 → NameResolutionSucceeded = False"
    )
    recommended_next_action     = "检查 DNS 配置或使用备用 DNS（如 8.8.8.8）"
    human_interaction_required  = $false
    human_action_detail         = $null
}
$output | ConvertTo-Json -Depth 4
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| 诊断通过对话式自由文本分析 | 脚本化、结构化 JSON 输出 | 本设计规格 (2026-05-13) | 主 Agent 可直接编程消费输出，无需 NLP 解析 |
| `nslookup` 文本解析 | `Resolve-DnsName` cmdlet | PowerShell 4.0+ (2013) | 返回结构化对象，消除文本解析脆弱性 |
| `$ErrorActionPreference = 'Stop'` + `try/catch` 处理外部命令 | `$ErrorActionPreference = 'Continue'` + `$LASTEXITCODE` 检查 | N/A (反模式) | 外部命令在 PS 中不受 ErrorActionPreference 影响，Stop 反而导致 2> bug |
| `Write-Host` / `Write-Output` 混合输出 | 仅 JSON 输出到 stdout，诊断日志到 stderr | 本设计 | 主 Agent 可安全地将 stdout 作为 JSON 解析，不受诊断日志干扰 |

**Deprecated/outdated:**
- `git config --get credential.helper` 返回 `wincred`：Windows 旧版凭据助手，已被 `manager`（Git Credential Manager Core）取代。但检查逻辑应兼容两者。
- PowerShell `curl` alias (Invoke-WebRequest)：在 Windows 10 17063+ 中，`curl.exe`（真实 curl）在 PATH 中。脚本使用 `curl.exe` 显式调用以避免 alias 冲突。

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `Resolve-DnsName -QuickTimeout` 参数在 PS 5.1 中可用 | DNS resolution | 如果该参数在更早的 PS 5.1 版本中不存在，DNS 检查可能超时较久。回退方案：移除 `-QuickTimeout` 并使用 `-DnsOnly` |
| A2 | `curl.exe` 在所有 Windows 11 系统中默认存在于 PATH 中 | Network path | 如果某些企业镜像移除了 curl.exe，HTTPS 探测失败。回退方案：使用 `Invoke-WebRequest` 或 `[System.Net.WebRequest]` |
| A3 | Windows 11 企业环境中的组策略不会阻止注册表读取 `HKCU:\...\Internet Settings` | Proxy detection | 如果注册表读取被组策略阻止，系统代理检测不完整。回退方案：仅依赖环境变量 |
| A4 | `git -C <path>` 参数在所有 Git 2.40+ 版本中可用 | Git command execution | 如果在更早版本中使用，需回退到 `Push-Location`/`Pop-Location` 模式 |

## Open Questions

1. **脚本的超时控制策略**
   - What we know: `Test-NetConnection` 默认有超时机制，`curl.exe` 支持 `--connect-timeout`。SSH 检查需要显式超时。
   - What's unclear: 整体脚本应设置多长的最大执行时间？每个网络探测的超时值应设为多少（建议 5 秒）？
   - Recommendation: 每个网络探测设置 5 秒超时（`curl.exe --connect-timeout 5`，`ssh -o ConnectTimeout=5`）。脚本总执行时间不应超过 30 秒。

2. **认证层中 SSH 密钥检查的深度**
   - What we know: 设计文档要求检查传输类型（HTTPS/SSH）和凭据助手配置。`ssh -T git@github.com` 可以验证 SSH 认证是否工作。
   - What's unclear: 脚本是否需要检查 SSH 密钥文件是否存在（`~/.ssh/id_rsa`、`~/.ssh/id_ed25519`）？还是仅通过 `ssh -T` 测试即可？
   - Recommendation: 仅通过 `ssh -T` 测试（先 TCP 22 探测确保可达性）。密钥文件存在不代表已添加到 GitHub。`ssh -T` 的结果是最权威的。

3. **脚本的输出语言**
   - What we know: 项目约定提交信息必须中文，文档使用中文。现有脚本的错误信息使用英文。
   - What's unclear: 结构化输出的 `problem_category`、`likely_cause`、`recommended_next_action` 字段应使用中文还是英文？主 Agent 消费中文是否困难？
   - Recommendation: 使用中文（与参考知识库保持一致）。主 Agent (Claude Code) 可以消费中文。这确保诊断结果可以直接呈现给用户。

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| PowerShell 5.1+ | Script runtime | Yes | 5.1.26100 | — |
| Git | All git command invocations | Yes | 2.54.0 | — |
| Test-NetConnection | TCP port 443/22 probing | Yes | built-in (NetTCPIP) | `[System.Net.Sockets.TcpClient]` |
| Resolve-DnsName | DNS resolution | Yes | built-in (DnsClient) | `[System.Net.Dns]::GetHostEntry()` |
| curl.exe | HTTPS reachability probe | Yes | built-in (Win 10 17063+) | `Invoke-WebRequest` |
| nslookup.exe | DNS resolution fallback | Yes | built-in | `Resolve-DnsName` (preferred) |
| ssh.exe | SSH authentication test | Yes | built-in | Skip SSH check if unavailable |

**Missing dependencies with no fallback:** None — all dependencies verified present on target system.

**Missing dependencies with fallback:** None.

## Validation Architecture

> Skipped — `workflow.nyquist_validation` is explicitly set to `false` in `.planning/config.json`.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | 脚本不处理认证数据，仅读取配置状态 |
| V3 Session Management | No | 无会话管理 |
| V4 Access Control | No | 脚本不在服务端运行 |
| V5 Input Validation | Yes | 验证 -RepoPath 为有效路径；消毒 -Stderr 输入以避免注入 |
| V6 Cryptography | No | 脚本不执行加密操作 |
| V7 Error Handling | Yes | 所有外部命令的输出在记录前消毒；错误信息不包含凭据 |
| V8 Data Protection | Yes | 脚本不记录凭据内容（仅记录凭据助手名称）；不输出 token/密码到 evidence 字段 |

### Known Threat Patterns for PowerShell Diagnostic Scripts

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Git credential leak via evidence field | Information Disclosure | 过滤 evidence 中的凭据相关模式（`Authorization: Basic`、token 前缀 `ghp_`、`github_pat_`） |
| Command injection via -Stderr parameter | Tampering | 永远不对用户提供的 stderr 字符串执行 eval 或 Invoke-Expression；仅做模式匹配 |
| Path traversal via -RepoPath | Tampering | 验证 -RepoPath 指向有效目录；使用 `Resolve-Path` 规范化；拒绝包含 `..` 的路径 |
| stdout pollution with sensitive data | Information Disclosure | 脚本仅输出 JSON 到 stdout；诊断日志（含敏感信息）写入 stderr 或仅记录结构化的非敏感摘要 |

## Sources

### Primary (HIGH confidence)
- 设计文档: `docs/superpowers/specs/2026-05-13-git-remote-diagnostics-design.md` — 第 7-10 章（诊断流程、输出契约、人工交互规则）[READ]
- Phase 1 输出: `skills/liam-git-workflow-remote-diagnose/SKILL.md` — 触发条件、诊断顺序、输出契约 [READ]
- Phase 1 输出: `references/remote-diagnostics.md` — 故障分类表、信号-原因映射、修复动作、交互边界 [READ]
- 项目约束: `./CLAUDE.md` — 运行时要求（Win 11, PS 5.1+, Git 2.40+）、提交语言要求 [READ]
- 现有脚本: `scripts/install.ps1`, `scripts/update.ps1`, `scripts/common.ps1` — 参数模式、错误处理、命名约定 [READ]
- Phase 1 Plan: `.planning/phases/01-diagnostic-foundation/01-01-PLAN.md` — 构造规范与接口契约 [READ]
- 本机验证: PowerShell 5.1.26100, Git 2.54.0, Test-NetConnection, Resolve-DnsName, curl.exe [BASH VERIFIED]
- 本机验证: ConvertTo-Json depth behavior, [ordered]@{} serialization [BASH VERIFIED]
- 本机验证: Proxy registry detection, credential helper (manager) [BASH VERIFIED]

### Secondary (MEDIUM confidence)
- Web search: PowerShell external command error handling — `$ErrorActionPreference` does not apply to native commands, `$LASTEXITCODE` usage [CROSS-REFERENCED]
- Web search: `Test-NetConnection` usage patterns — `-InformationLevel Detailed` vs `Quiet`, TCP timeout vs refused distinction [CROSS-REFERENCED with Microsoft TechCommunity]
- Web search: `Resolve-DnsName` cmdlet documentation — structured DNS resolution, `-QuickTimeout` parameter [CROSS-REFERENCED with Microsoft docs]
- Web search: PowerShell `ConvertTo-Json` depth and `[ordered]` pattern [CROSS-REFERENCED with multiple sources]
- Web search: Windows proxy detection via registry `HKCU:\...\Internet Settings` [CROSS-REFERENCED with Microsoft TechNet]

### Tertiary (LOW confidence)
- None — all web search findings cross-referenced with at least one secondary source or local verification.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — all tools verified present on target system; versions confirmed via Get-Command and --version
- Architecture: HIGH — patterns derived from existing project scripts and verified against PS 5.1 behavior on this system
- Pitfalls: HIGH — PS 5.1 `$ErrorActionPreference` + `2>` bug verified against official GitHub issue; ConvertTo-Json depth verified locally

**Research date:** 2026-05-25
**Valid until:** 2026-06-25 (stable domain — PowerShell 5.1 and Git are mature, low-change-rate technologies)
