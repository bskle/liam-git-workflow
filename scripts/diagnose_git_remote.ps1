<#
.SYNOPSIS
    Git 远程操作故障诊断脚本——五层系统性检查。

.DESCRIPTION
    收集本地 Git 状态、远程配置、认证信息、网络路径和仓库策略，
    产出结构化 JSON 结论供主 Agent 消费。
    乐观收集模式：即使早期层发现问题，也继续执行所有五层诊断。
    仅在 CLI 不可观测的信息时请求人工交互。

.PARAMETER RepoPath
    Git 仓库路径。默认：当前工作目录。

.PARAMETER RemoteName
    要诊断的远程名称。默认："origin"。

.PARAMETER FailedCommand
    触发诊断的失败命令（push/pull/fetch/ls-remote）。可选。

.PARAMETER Stderr
    失败命令的 stderr 输出。可选——用于模式匹配。

.EXAMPLE
    .\diagnose_git_remote.ps1 -RepoPath "C:\project" -RemoteName "origin" -FailedCommand "push" -Stderr "fatal: unable to access..."
#>

param(
    [string]$RepoPath = (Get-Location).Path,
    [string]$RemoteName = 'origin',
    [string]$FailedCommand = '',
    [string]$Stderr = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'
$script:Stderr = $Stderr

function Invoke-DiagnosticCommand {
    param(
        [string]$CommandName,
        [scriptblock]$ScriptBlock
    )
    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $output = ''
    $exitCode = 0
    $errorMsg = $null
    try {
        $output = & $ScriptBlock 2>&1 | Out-String
        $exitCode = $LASTEXITCODE
    } catch {
        $errorMsg = $_.Exception.Message
        $exitCode = $LASTEXITCODE
        if ($exitCode -eq 0) { $exitCode = -1 }
    }
    $ErrorActionPreference = $prevEAP
    return @{ Output = $output; ExitCode = $exitCode; Error = $errorMsg }
}

function Invoke-GitCommand {
    param(
        [string]$RepoPath,
        [string[]]$Arguments
    )
    return Invoke-DiagnosticCommand -CommandName "git $($Arguments -join ' ')" -ScriptBlock {
        & git -C $RepoPath @Arguments 2>&1 | Out-String
    }
}

function Test-Preconditions {
    param(
        [string]$RepoPath,
        [string]$RemoteName
    )
    if (-not (Test-Path -LiteralPath $RepoPath -PathType Container)) {
        $result = [ordered]@{
            problem_category           = "参数错误"
            evidence                   = @("指定的仓库路径不存在: $RepoPath")
            likely_cause               = "指定的仓库路径不存在: $RepoPath"
            confidence                 = "high"
            actions_taken              = @("Test-Path -LiteralPath '$RepoPath' -PathType Container -> False")
            recommended_next_action    = "请检查 -RepoPath 参数是否正确，确保路径指向一个存在的目录"
            human_interaction_required = $false
            human_action_detail        = $null
        }
        Write-Output ($result | ConvertTo-Json -Depth 4 -Compress)
        exit 1
    }
    $gitCheck = Invoke-GitCommand -RepoPath $RepoPath -Arguments 'rev-parse', '--git-dir'
    if ($gitCheck.ExitCode -ne 0) {
        $result = [ordered]@{
            problem_category           = "本地状态阻塞"
            evidence                   = @("当前目录不是 Git 仓库: git rev-parse --git-dir 返回非零退出码")
            likely_cause               = "当前目录不是 Git 仓库"
            confidence                 = "high"
            actions_taken              = @("git rev-parse --git-dir -> exit code: $($gitCheck.ExitCode), output: $($gitCheck.Output.Trim())")
            recommended_next_action    = "请切换到有效的 Git 仓库目录，或使用 git init 初始化新仓库"
            human_interaction_required = $false
            human_action_detail        = $null
        }
        Write-Output ($result | ConvertTo-Json -Depth 4 -Compress)
        exit 1
    }
}

function Test-LocalRepositoryState {
    param([string]$RepoPath)
    $evidence = @()
    $actions = @()
    $findings = @{}

    $branchResult = Invoke-GitCommand -RepoPath $RepoPath -Arguments 'branch', '--show-current'
    $branchOutput = $branchResult.Output.Trim()
    $actions += "git branch --show-current -> exit=$($branchResult.ExitCode), output='$branchOutput'"

    if ($branchResult.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($branchOutput)) {
        $evidence += "当前处于 detached HEAD 状态（git branch --show-current 输出为空）"
        $findings['detached_head'] = $true
    } else {
        $evidence += "当前分支: $branchOutput（正常）"
        $findings['current_branch'] = $branchOutput
    }

    $mergeHeadPath = Join-Path $RepoPath '.git' 'MERGE_HEAD'
    if (Test-Path -LiteralPath $mergeHeadPath) {
        $evidence += "检测到 merge 进行中（.git/MERGE_HEAD 存在）"
        $findings['merge_in_progress'] = $true
        $actions += "Test-Path '$mergeHeadPath' -> True（merge 进行中）"
    } else {
        $actions += "Test-Path '$mergeHeadPath' -> False"
    }

    $rebaseMergePath = Join-Path $RepoPath '.git' 'rebase-merge'
    $rebaseApplyPath = Join-Path $RepoPath '.git' 'rebase-apply'
    $rebaseMergeExists = Test-Path -LiteralPath $rebaseMergePath
    $rebaseApplyExists = Test-Path -LiteralPath $rebaseApplyPath

    if ($rebaseMergeExists -or $rebaseApplyExists) {
        $rebaseDir = if ($rebaseMergeExists) { '.git/rebase-merge' } else { '.git/rebase-apply' }
        $evidence += "检测到 rebase 进行中（$rebaseDir 存在）"
        $findings['rebase_in_progress'] = $true
    }
    $actions += "Test-Path '$rebaseMergePath' -> $rebaseMergeExists"
    $actions += "Test-Path '$rebaseApplyPath' -> $rebaseApplyExists"

    $statusResult = Invoke-GitCommand -RepoPath $RepoPath -Arguments 'status', '--porcelain'
    $statusOutput = $statusResult.Output
    $actions += "git status --porcelain -> exit=$($statusResult.ExitCode)"

    if ($statusOutput -match 'UU ') {
        $evidence += "检测到未解决的合并冲突（git status --porcelain 包含 UU 状态）"
        $findings['has_conflicts'] = $true
    }

    if ($statusOutput -match '^[MADR? ]') {
        $changedCount = ($statusOutput -split "`n" | Where-Object { $_ -match '^\S' } | Measure-Object).Count
        $evidence += "检测到 $changedCount 个未提交的变更"
        $findings['has_uncommitted_changes'] = $true
    } else {
        $findings['has_uncommitted_changes'] = $false
        $evidence += "工作区干净，无未提交变更"
    }

    $branchVVResult = Invoke-GitCommand -RepoPath $RepoPath -Arguments 'branch', '-vv'
    $branchVV = $branchVVResult.Output
    $actions += "git branch -vv -> exit=$($branchVVResult.ExitCode)"

    $currentBranchLine = ($branchVV -split "`n" | Where-Object { $_ -match '^\*' } | Select-Object -First 1)

    if ($currentBranchLine) {
        if ($currentBranchLine -match '\[([^]]+)\]') {
            $upstreamInfo = $Matches[1]
            if ($upstreamInfo -match ': gone\]') {
                $evidence += "检测到 upstream 分支已删除: $upstreamInfo"
                $findings['upstream_gone'] = $true
            } else {
                $evidence += "当前分支 upstream 配置: $upstreamInfo（正常）"
            }
        } else {
            $evidence += "当前分支未设置 upstream（git branch -vv 中无 [remote/branch] 标记）"
            $findings['no_upstream'] = $true
        }
    }

    return @{ Evidence = $evidence; Actions = $actions; Findings = $findings }
}

function Test-RemoteTarget {
    param(
        [string]$RepoPath,
        [string]$RemoteName
    )
    $evidence = @()
    $actions = @()
    $findings = @{}

    $remoteResult = Invoke-GitCommand -RepoPath $RepoPath -Arguments 'remote', '-v'
    $remoteOutput = $remoteResult.Output.Trim()
    $actions += "git remote -v -> exit=$($remoteResult.ExitCode)"

    if ([string]::IsNullOrWhiteSpace($remoteOutput)) {
        $evidence += "未配置任何远程仓库"
        $findings['no_remotes'] = $true
    } else {
        $remoteLines = $remoteOutput -split "`n" | Where-Object { $_ -match '^\S+' }
        foreach ($line in $remoteLines) {
            if ($line -match "^$RemoteName\s+(\S+)\s+\(fetch\)") {
                $fetchUrl = $Matches[1]
                $findings['remote_url'] = $fetchUrl
                $evidence += "远程仓库 $RemoteName URL: $fetchUrl"
                break
            }
        }
        if (-not $findings.ContainsKey('remote_url') -and $remoteLines.Count -gt 0) {
            $allNames = ($remoteLines | ForEach-Object { ($_ -split '\s+')[0] } | Select-Object -Unique) -join ', '
            $evidence += "未找到名称为 '$RemoteName' 的远程仓库。已配置的远程: $allNames"
            $findings['remote_name_not_found'] = $true
        }
    }

    if ($findings.ContainsKey('remote_url')) {
        $url = $findings['remote_url']
        if ($url -match '^https://([^/]+)/([^/]+/[^/]+?)(\.git)?$') {
            $findings['ParsedHost'] = $Matches[1]
            $evidence += "远程 URL 格式正常: HTTPS -> $($Matches[1])"
        } elseif ($url -match '^git@([^:]+):(.+?)(\.git)?$') {
            $findings['ParsedHost'] = $Matches[1]
            $evidence += "远程 URL 格式正常: SSH -> $($Matches[1])"
        } else {
            $evidence += "远程 URL 格式异常: $url —— 不符合 HTTPS 或 SSH 标准格式"
            $findings['url_malformed'] = $true
        }
    }

    $branchVVResult = Invoke-GitCommand -RepoPath $RepoPath -Arguments 'branch', '-vv'
    $branchVV = $branchVVResult.Output
    $actions += "git branch -vv (Layer 2) -> exit=$($branchVVResult.ExitCode)"
    $currentBranchLine = ($branchVV -split "`n" | Where-Object { $_ -match '^\*' } | Select-Object -First 1)
    if ($currentBranchLine) {
        if ($currentBranchLine -match '\[([^/]+)/([^\]:]+)') {
            $upstreamRemote = $Matches[1]
            if ($upstreamRemote -ne $RemoteName) {
                $evidence += "当前分支 upstream 指向 '$upstreamRemote'，而非指定的 '$RemoteName'"
            }
        }
        if ($currentBranchLine -match ': gone\]') {
            $findings['upstream_gone'] = $true
            $evidence += "远程 upstream 分支已被删除（标记为 ': gone]'）"
        }
    }

    $lsRemoteResult = Invoke-GitCommand -RepoPath $RepoPath -Arguments 'ls-remote', '--heads', $RemoteName
    $lsRemoteOutput = $lsRemoteResult.Output.Trim()
    $actions += "git ls-remote $RemoteName --heads -> exit=$($lsRemoteResult.ExitCode)"
    if ($lsRemoteResult.ExitCode -eq 0) {
        $branchCount = ($lsRemoteOutput -split "`n" | Where-Object { $_ -match '\S' } | Measure-Object).Count
        $evidence += "git ls-remote $RemoteName --heads 成功，发现 $branchCount 个分支引用"
        $findings['ls_remote_heads_ok'] = $true
    } else {
        $errorPreview = if ($lsRemoteOutput.Length -gt 200) { $lsRemoteOutput.Substring(0, 200) + '...' } else { $lsRemoteOutput }
        $evidence += "git ls-remote $RemoteName --heads 失败 (exit=$($lsRemoteResult.ExitCode)): $errorPreview"
        $findings['ls_remote_heads_ok'] = $false
        $findings['ls_remote_heads_error'] = $lsRemoteOutput
    }

    return @{ Evidence = $evidence; Actions = $actions; Findings = $findings }
}

function Test-Authentication {
    param(
        [string]$RepoPath,
        [string]$RemoteName,
        [string]$RemoteUrl
    )
    $evidence = @()
    $actions = @()
    $findings = @{}

    if ($RemoteUrl -match '^https://') {
        $findings['transport'] = 'HTTPS'
        $evidence += "传输类型: HTTPS"
    } elseif ($RemoteUrl -match '^git@') {
        $findings['transport'] = 'SSH'
        $evidence += "传输类型: SSH"
    } else {
        $findings['transport'] = 'unknown'
        $evidence += "传输类型: 未知（URL: $RemoteUrl）"
    }

    $credHelperResult = Invoke-GitCommand -RepoPath $RepoPath -Arguments 'config', '--get', 'credential.helper'
    $credHelper = $credHelperResult.Output.Trim()
    $actions += "git config --get credential.helper -> exit=$($credHelperResult.ExitCode), output='$credHelper'"
    if ([string]::IsNullOrWhiteSpace($credHelper)) {
        $evidence += "未配置 Git 凭据助手"
        $findings['no_credential_helper'] = $true
    } else {
        $evidence += "Git 凭据助手: $credHelper"
        $findings['credential_helper'] = $credHelper
    }

    if ($findings['transport'] -eq 'HTTPS') {
        $credShowResult = Invoke-GitCommand -RepoPath $RepoPath -Arguments 'config', '--get', '--show-origin', 'credential.helper'
        $credShow = $credShowResult.Output.Trim()
        $actions += "git config --get --show-origin credential.helper -> exit=$($credShowResult.ExitCode)"
        if (-not [string]::IsNullOrWhiteSpace($credShow)) {
            $evidence += "凭据助手配置来源: $credShow"
        }
    }

    if ($findings['transport'] -eq 'SSH' -and $RemoteUrl -match '^git@([^:]+):') {
        $sshHost = $Matches[1]
        $sshUser = 'git'
        $tcp22Result = Test-NetConnection -ComputerName $sshHost -Port 22 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
        $actions += "Test-NetConnection $sshHost -Port 22 -> TcpTestSucceeded=$($tcp22Result.TcpTestSucceeded)"
        if ($tcp22Result.TcpTestSucceeded) {
            $evidence += "SSH 端口 22 可达: $sshHost"
            $sshResult = Invoke-DiagnosticCommand -CommandName "ssh" -ScriptBlock {
                ssh -o ConnectTimeout=5 -o BatchMode=yes -T "${sshUser}@${sshHost}" 2>&1 | Out-String
            }
            $sshOutput = $sshResult.Output.Trim()
            $actions += "ssh -o ConnectTimeout=5 -T ${sshUser}@${sshHost} -> exit=$($sshResult.ExitCode)"
            if ($sshResult.ExitCode -eq 1 -and $sshOutput -match 'successfully authenticated') {
                $evidence += "SSH 认证成功 (ssh -T ${sshUser}@${sshHost})"
                $findings['ssh_auth_ok'] = $true
            } elseif ($sshOutput -match 'Permission denied') {
                $evidence += "SSH 认证失败: Permission denied"
                $findings['ssh_auth_failed'] = $true
            } else {
                $evidence += "SSH 认证结果不确定 (exit=$($sshResult.ExitCode)): $($sshOutput.Substring(0, [Math]::Min(200, $sshOutput.Length)))"
            }
        } else {
            $evidence += "SSH 端口 22 不可达——可能被防火墙阻止"
            $findings['ssh_port_blocked'] = $true
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($script:Stderr)) {
        $stderrText = $script:Stderr
        if ($stderrText -match 'fatal: Authentication failed') {
            $evidence += "stderr 包含认证失败签名: Authentication failed"
            $findings['auth_error_401'] = $true
        }
        if ($stderrText -match 'HTTP 403|returned error: 403') {
            $evidence += "stderr 包含授权拒绝签名: HTTP 403"
            $findings['auth_error_403'] = $true
        }
        if ($stderrText -match 'Permission denied.*publickey') {
            $evidence += "stderr 包含 SSH 公钥拒绝签名: Permission denied (publickey)"
            $findings['ssh_key_denied'] = $true
        }
    }

    return @{ Evidence = $evidence; Actions = $actions; Findings = $findings }
}

# ============================================================
# Diagnostic Layer 4: Network Path
# ============================================================

function Test-NetworkPath {
    param(
        [string]$RepoPath,
        [string]$RemoteName,
        [string]$RemoteUrl
    )

    $evidence = @()
    $actions = @()
    $findings = @{}

    # Extract hostname from RemoteUrl
    $hostname = 'github.com'
    if ($RemoteUrl -match '^https://([^/]+)') {
        $hostname = $Matches[1]
    } elseif ($RemoteUrl -match '^git@([^:]+)') {
        $hostname = $Matches[1]
    }
    $findings['remote_host'] = $hostname

    # a) Git HTTP/HTTPS proxy configuration
    $httpProxyResult = Invoke-GitCommand -RepoPath $RepoPath -Arguments 'config', '--get', 'http.proxy'
    $httpProxy = $httpProxyResult.Output.Trim()
    $actions += "git config --get http.proxy -> exit=$($httpProxyResult.ExitCode), output='$httpProxy'"
    if ([string]::IsNullOrWhiteSpace($httpProxy)) {
        $evidence += "未配置 Git HTTP 代理"
    } else {
        $evidence += "Git HTTP 代理: $httpProxy"
        $findings['git_http_proxy'] = $httpProxy
    }

    $httpsProxyResult = Invoke-GitCommand -RepoPath $RepoPath -Arguments 'config', '--get', 'https.proxy'
    $httpsProxy = $httpsProxyResult.Output.Trim()
    $actions += "git config --get https.proxy -> exit=$($httpsProxyResult.ExitCode), output='$httpsProxy'"
    if ([string]::IsNullOrWhiteSpace($httpsProxy)) {
        if ([string]::IsNullOrWhiteSpace($httpProxy)) {
            $evidence += "未配置 Git HTTP/HTTPS 代理"
        }
    } else {
        $evidence += "Git HTTPS 代理: $httpsProxy"
        $findings['git_https_proxy'] = $httpsProxy
    }

    # b) Shell environment proxy variables (Windows)
    $envHttpProxy = [System.Environment]::GetEnvironmentVariable('HTTP_PROXY')
    $envHttpsProxy = [System.Environment]::GetEnvironmentVariable('HTTPS_PROXY')
    $envNoProxy = [System.Environment]::GetEnvironmentVariable('NO_PROXY')

    if ([string]::IsNullOrWhiteSpace($envHttpProxy) -and [string]::IsNullOrWhiteSpace($envHttpsProxy)) {
        $evidence += "未配置环境代理变量（HTTP_PROXY/HTTPS_PROXY）"
    } else {
        if (-not [string]::IsNullOrWhiteSpace($envHttpProxy)) {
            $evidence += "环境 HTTP_PROXY: $envHttpProxy"
            $findings['env_http_proxy'] = $envHttpProxy
        }
        if (-not [string]::IsNullOrWhiteSpace($envHttpsProxy)) {
            $evidence += "环境 HTTPS_PROXY: $envHttpsProxy"
            $findings['env_https_proxy'] = $envHttpsProxy
        }
        if (-not [string]::IsNullOrWhiteSpace($envNoProxy)) {
            $findings['env_no_proxy'] = $envNoProxy
        }
    }
    $actions += "环境代理变量: HTTP_PROXY=$envHttpProxy, HTTPS_PROXY=$envHttpsProxy, NO_PROXY=$envNoProxy"

    # c) Windows system proxy detection (registry)
    try {
        $reg = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction Stop
        $proxyEnabled = ($reg.ProxyEnable -eq 1)
        $proxyServer = $reg.ProxyServer
        $evidence += "Windows 系统代理: $(if ($proxyEnabled) { '启用' } else { '禁用' })"
        if ($proxyEnabled -and $proxyServer) {
            $evidence += "Windows 系统代理服务器: $proxyServer"
        }
        $findings['system_proxy_enabled'] = $proxyEnabled
        $findings['system_proxy_server'] = $proxyServer
        $actions += "注册表读取 Internet Settings -> ProxyEnable=$proxyEnabled, ProxyServer=$proxyServer"
    } catch {
        $evidence += "无法读取 Windows 系统代理配置（注册表访问受限）"
        $findings['system_proxy_readable'] = $false
        $actions += "注册表读取 Internet Settings -> 失败（访问受限）"
    }

    # d) DNS resolution (with .NET fallback)
    try {
        $dnsResult = Resolve-DnsName -Name $hostname -Type A -QuickTimeout -ErrorAction Stop
        $ips = ($dnsResult | Where-Object { $_.QueryType -eq 'A' }).IPAddress
        $evidence += "DNS 解析成功: $hostname -> $($ips -join ', ')"
        $findings['dns_resolved'] = $true
        $findings['dns_ips'] = @($ips)
        $actions += "Resolve-DnsName $hostname -Type A -> $($ips -join ', ')"
    } catch {
        # Fallback to [System.Net.Dns]::GetHostEntry()
        try {
            $entry = [System.Net.Dns]::GetHostEntry($hostname)
            $ips = @($entry.AddressList | Where-Object { $_.AddressFamily -eq 'InterNetwork' } | ForEach-Object { $_.IPAddressToString })
            $evidence += "DNS 解析成功（.NET 回退）: $hostname -> $($ips -join ', ')"
            $findings['dns_resolved'] = $true
            $findings['dns_ips'] = @($ips)
            $actions += "[System.Net.Dns]::GetHostEntry($hostname) -> $($ips -join ', ')（回退方案）"
        } catch {
            $evidence += "DNS 解析失败: $hostname —— $($_.Exception.Message)"
            $findings['dns_resolved'] = $false
            $findings['dns_error'] = $_.Exception.Message
            $actions += "DNS 解析 $hostname -> 失败: $($_.Exception.Message)"
        }
    }

    # e) TCP 443 reachability
    $tcp443Result = Test-NetConnection -ComputerName $hostname -Port 443 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
    $actions += "Test-NetConnection $hostname -Port 443 -> TcpTestSucceeded=$($tcp443Result.TcpTestSucceeded)"
    $evidence += "TCP 443 $hostname`: TcpTestSucceeded = $($tcp443Result.TcpTestSucceeded), PingSucceeded = $($tcp443Result.PingSucceeded)"
    $findings['tcp_443_reachable'] = $tcp443Result.TcpTestSucceeded

    # f) HTTPS minimal probe via curl.exe
    $curlResult = Invoke-DiagnosticCommand -CommandName "curl.exe" -ScriptBlock {
        curl.exe -I --connect-timeout 5 --max-time 10 "https://$hostname" 2>&1 | Out-String
    }
    $curlOutput = $curlResult.Output.Trim()
    $actions += "curl.exe -I https://$hostname -> exit=$($curlResult.ExitCode)"

    if ($curlResult.ExitCode -eq 0) {
        $evidence += "HTTPS 探测成功: $hostname 返回 HTTP 响应头"
        $findings['https_probe_ok'] = $true
    } else {
        $errorPreview = if ($curlOutput.Length -gt 200) { $curlOutput.Substring(0, 200) + '...' } else { $curlOutput }
        $evidence += "HTTPS 探测失败: $hostname (exit code: $($curlResult.ExitCode)): $errorPreview"
        $findings['https_probe_ok'] = $false
        $findings['https_probe_error'] = $curlOutput
    }

    # g) git ls-remote narrowband test (full remote, not just --heads)
    $lsRemoteFullResult = Invoke-GitCommand -RepoPath $RepoPath -Arguments 'ls-remote', $RemoteName
    $lsRemoteFullOutput = $lsRemoteFullResult.Output.Trim()
    $actions += "git ls-remote $RemoteName -> exit=$($lsRemoteFullResult.ExitCode)"

    if ($lsRemoteFullResult.ExitCode -eq 0) {
        $evidence += "git ls-remote $RemoteName 成功"
        $findings['ls_remote_ok'] = $true
    } else {
        $errorPreview = if ($lsRemoteFullOutput.Length -gt 200) { $lsRemoteFullOutput.Substring(0, 200) + '...' } else { $lsRemoteFullOutput }
        $evidence += "git ls-remote $RemoteName 失败 (exit=$($lsRemoteFullResult.ExitCode)): $errorPreview"
        $findings['ls_remote_ok'] = $false
        $findings['ls_remote_error'] = $lsRemoteFullOutput
    }

    return @{ Evidence = $evidence; Actions = $actions; Findings = $findings }
}

# ============================================================
# Diagnostic Layer 5: Repository Policy
# ============================================================

function Test-RepositoryPolicy {
    param(
        [string]$Stderr
    )

    $evidence = @()
    $actions = @()
    $findings = @{}

    if ([string]::IsNullOrWhiteSpace($Stderr)) {
        $evidence += "未提供失败命令的 stderr 输出，跳过策略层模式匹配"
        $actions += "Test-RepositoryPolicy: Stderr 参数为空，跳过"
    } else {
        $actions += "Test-RepositoryPolicy: 对 stderr 进行模式匹配"

        # a) Protected branch
        if ($Stderr -match 'protected branch') {
            $evidence += "检测到受保护分支信号: stderr 包含 'protected branch'"
            $findings['protected_branch'] = $true
            $actions += "stderr -match 'protected branch' -> True"
        }

        # b) Non-fast-forward / force push rejected
        if ($Stderr -match 'non-fast-forward|Updates were rejected') {
            $evidence += "检测到非 fast-forward 拒绝: stderr 包含 'non-fast-forward' 或 'Updates were rejected'"
            $findings['non_fast_forward'] = $true
            $actions += "stderr -match 'non-fast-forward|Updates were rejected' -> True"
        }

        # c) Repository not found
        if ($Stderr -match 'repository not found|HTTP 404') {
            $evidence += "检测到仓库不存在信号: stderr 包含 'repository not found' 或 'HTTP 404'"
            $findings['repo_not_found'] = $true
            $actions += "stderr -match 'repository not found|HTTP 404' -> True"
        }

        # d) Organization policy
        if ($Stderr -match 'required status check|required review|IP allow|2FA|organization policy') {
            $evidence += "检测到组织策略限制信号: stderr 包含策略相关关键词"
            $findings['org_policy'] = $true
            $actions += "stderr -match 'required status check|required review|IP allow|2FA|organization policy' -> True"
        }

        # e) No policy signals found
        if (-not $findings.ContainsKey('protected_branch') -and
            -not $findings.ContainsKey('non_fast_forward') -and
            -not $findings.ContainsKey('repo_not_found') -and
            -not $findings.ContainsKey('org_policy')) {
            $evidence += "未检测到服务端策略拒绝信号"
            $actions += "stderr 模式匹配: 未匹配到任何策略信号"
        }
    }

    return @{ Evidence = $evidence; Actions = $actions; Findings = $findings }
}

# ============================================================
# Signal-to-Cause Mapping Engine
# ============================================================

function Resolve-RootCause {
    param(
        [string[]]$AllEvidence,
        [hashtable]$AllFindings
    )

    $patterns = @(
        # === high confidence signals ===
        @{ Pattern = '不是 Git 仓库|not a git repository'; Category = '本地状态阻塞'; Cause = '当前目录不是 Git 仓库或 .git 目录已损坏'; Confidence = 'high' },
        @{ Pattern = 'detached HEAD|not currently on a branch'; Category = '本地状态阻塞'; Cause = '处于 detached HEAD 状态，无法执行远程操作'; Confidence = 'high' },
        @{ Pattern = 'merge 进行中|MERGE_HEAD'; Category = '本地状态阻塞'; Cause = 'merge 操作进行中，需先完成或中止'; Confidence = 'high' },
        @{ Pattern = 'rebase 进行中|rebase-merge|rebase-apply'; Category = '本地状态阻塞'; Cause = 'rebase 操作进行中，需先完成或中止'; Confidence = 'high' },
        @{ Pattern = '未设置 upstream|no upstream'; Category = '远程目标错误'; Cause = '当前分支未设置 upstream，无法确定推送目标'; Confidence = 'high' },
        @{ Pattern = '未配置.*远程|no remotes'; Category = '远程目标错误'; Cause = '仓库未配置任何远程仓库'; Confidence = 'high' },
        @{ Pattern = 'URL 格式.*异常|protocol.*not supported'; Category = '远程目标错误'; Cause = '远程 URL 格式错误'; Confidence = 'high' },
        @{ Pattern = 'Could not resolve host|Name or service not known|DNS 解析失败'; Category = 'DNS 解析失败'; Cause = 'DNS 无法解析 Git 服务域名——可能由于企业 DNS 过滤或网络断开'; Confidence = 'high' },
        @{ Pattern = 'Connection timed out|Connection refused|TcpTestSucceeded = False'; Category = '连接超时/拒绝'; Cause = '无法建立到 Git 服务的 TCP 连接——可能被防火墙阻止或网络不通'; Confidence = 'high' },
        @{ Pattern = 'Authentication failed.*https|fatal: Authentication failed'; Category = '认证失败'; Cause = 'HTTPS 凭据错误或已过期'; Confidence = 'high' },
        @{ Pattern = 'Permission denied.*publickey'; Category = '认证失败'; Cause = 'SSH 公钥未注册到 Git 服务或权限不足'; Confidence = 'high' },
        @{ Pattern = 'returned error: 403|HTTP 403'; Category = '授权不足'; Cause = '凭据有效但权限范围不足（Token 缺少 repo 权限或 SSO 未认证）'; Confidence = 'high' },
        @{ Pattern = 'protected branch'; Category = '仓库策略拒绝'; Cause = '目标分支受保护，禁止直接推送——需通过 PR 合并'; Confidence = 'high' },
        @{ Pattern = 'repository not found.*fatal|HTTP 404.*not found'; Category = '仓库不存在'; Cause = '仓库可能已删除、重命名或无权访问'; Confidence = 'high' },
        @{ Pattern = 'Updates were rejected.*remote contains'; Category = '本地状态阻塞'; Cause = '远程分支有本地不存在的提交——需先 pull/rebase'; Confidence = 'high' },
        # === medium confidence signals ===
        @{ Pattern = 'schannel.*InitializeSecurityContext failed'; Category = 'TLS/SSL 错误'; Cause = 'Windows TLS/Schannel 证书链验证失败——常见于企业自签名证书代理环境'; Confidence = 'medium' },
        @{ Pattern = 'SSL certificate problem|self signed certificate'; Category = 'TLS/SSL 错误'; Cause = 'SSL 证书链验证失败——可能由企业自签名证书或代理 SSL 拦截引起'; Confidence = 'medium' },
        @{ Pattern = 'Proxy CONNECT aborted|tunneling socket.*not established|HTTP 407'; Category = '代理错误'; Cause = '代理服务器连接失败——代理地址、端口或认证配置可能不正确'; Confidence = 'medium' },
        @{ Pattern = 'Connection was reset|Recv failure'; Category = '代理错误'; Cause = '代理或服务端重置连接——可能由于代理配置不匹配或 TLS 版本不兼容'; Confidence = 'medium' },
        @{ Pattern = 'uncommitted|未提交'; Category = '本地状态阻塞'; Cause = '存在未提交的变更'; Confidence = 'medium' },
        @{ Pattern = 'TCP 22.*False|SSH.*port.*blocked'; Category = '连接超时/拒绝'; Cause = 'SSH 端口 22 被防火墙阻止——尝试切换为 HTTPS 传输'; Confidence = 'medium' }
    )

    # Merge all evidence into a single string
    $allText = ($AllEvidence -join "`n") + "`n" + ($AllFindings.Keys | ForEach-Object { "$_ = $($AllFindings[$_])" }) -join "`n"

    # Sort patterns by confidence: high > medium > low
    $sortedPatterns = $patterns | Sort-Object { if ($_.Confidence -eq 'high') { 0 } elseif ($_.Confidence -eq 'medium') { 1 } else { 2 } }

    foreach ($p in $sortedPatterns) {
        if ($allText -match $p.Pattern) {
            return @{ Category = $p.Category; Cause = $p.Cause; Confidence = $p.Confidence }
        }
    }

    # No match found
    return @{
        Category   = '未知'
        Cause      = '诊断未匹配到已知故障模式——请人工分析 evidence 输出'
        Confidence = 'low'
    }
}

# ============================================================
# Structured Output Builder
# ============================================================

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
        problem_category           = $ProblemCategory
        evidence                   = [array]$Evidence
        likely_cause               = $LikelyCause
        confidence                 = $Confidence
        actions_taken              = [array]$ActionsTaken
        recommended_next_action    = $RecommendedNextAction
        human_interaction_required = $HumanInteractionRequired
        human_action_detail        = $(if ($HumanInteractionRequired) { $HumanActionDetail } else { $null })
    }

    return $result | ConvertTo-Json -Depth 4 -Compress
}

# ============================================================
# Main Flow Orchestration
# ============================================================

# Step 0: Pre-processing
$script:Stderr = $Stderr

# Step 1: Preconditions check
$precheck = Test-Preconditions -RepoPath $RepoPath -RemoteName $RemoteName
# Test-Preconditions will output JSON and exit if not a git repo; otherwise continues

# Step 2: Optimistic collection — all five layers execute
$allEvidence = @()
$allActions = @()
$allFindings = @{}

# Layer 1: Local Repository State
$layer1 = Test-LocalRepositoryState -RepoPath $RepoPath
$allEvidence += $layer1.Evidence
$allActions += $layer1.Actions
foreach ($key in $layer1.Findings.Keys) { $allFindings[$key] = $layer1.Findings[$key] }

# Layer 2: Remote Target Validation
$layer2 = Test-RemoteTarget -RepoPath $RepoPath -RemoteName $RemoteName
$allEvidence += $layer2.Evidence
$allActions += $layer2.Actions
foreach ($key in $layer2.Findings.Keys) { $allFindings[$key] = $layer2.Findings[$key] }

# Layer 3: Authentication and Authorization
$remoteUrl = if ($allFindings.ContainsKey('remote_url')) { $allFindings['remote_url'] } else { '' }
$layer3 = Test-Authentication -RepoPath $RepoPath -RemoteName $RemoteName -RemoteUrl $remoteUrl
$allEvidence += $layer3.Evidence
$allActions += $layer3.Actions
foreach ($key in $layer3.Findings.Keys) { $allFindings[$key] = $layer3.Findings[$key] }

# Layer 4: Network Path
$layer4 = Test-NetworkPath -RepoPath $RepoPath -RemoteName $RemoteName -RemoteUrl $remoteUrl
$allEvidence += $layer4.Evidence
$allActions += $layer4.Actions
foreach ($key in $layer4.Findings.Keys) { $allFindings[$key] = $layer4.Findings[$key] }

# Layer 5: Repository Policy
$layer5 = Test-RepositoryPolicy -Stderr $Stderr
$allEvidence += $layer5.Evidence
$allActions += $layer5.Actions
foreach ($key in $layer5.Findings.Keys) { $allFindings[$key] = $layer5.Findings[$key] }

# Step 3: Signal mapping -> root cause analysis
$rootCause = Resolve-RootCause -AllEvidence $allEvidence -AllFindings $allFindings

# Step 4: Determine human interaction requirement
$needsHuman = $false
$humanDetail = $null

switch -Wildcard ($rootCause.Category) {
    '仓库策略拒绝' {
        $needsHuman = $true
        $humanDetail = "无法从命令行确认仓库策略的具体配置。请在浏览器中检查仓库设置：1) 访问仓库的 Settings -> Branches，查看分支保护规则；2) 确认是否启用了 'Require a pull request before merging'。回报：分支保护规则的具体配置（是否要求 PR、是否要求审查、是否要求状态检查）。"
    }
    '仓库不存在' {
        $needsHuman = $true
        $humanDetail = "无法从命令行确认仓库的当前状态。请在浏览器中：1) 访问仓库 URL，确认仓库是否存在；2) 检查仓库是否已被删除、重命名或归档；3) 确认您的账号是否有该仓库的访问权限。回报：仓库是否存在、仓库的可见性（public/private）、您的访问权限级别。"
    }
    '授权不足' {
        $needsHuman = $true
        $humanDetail = "无法从命令行确认您的账号授权范围。请在浏览器中：1) 访问 GitHub Settings -> Personal Access Tokens，检查当前 Token 的权限范围（至少需要 'repo' 权限）；2) 如果是组织仓库，访问组织 SSO 授权页面确认 SSO 认证状态。回报：Token 的权限范围，以及 SSO 认证状态（已认证/未认证）。"
    }
    'TLS/SSL 错误' {
        $needsHuman = $true
        $humanDetail = "无法从命令行确认系统证书存储状态。此问题可能由企业自签名证书或代理 SSL 拦截引起。请在 Windows 上：1) 打开 certmgr.msc；2) 浏览到 '受信任的根证书颁发机构' -> '证书'；3) 查找是否有企业 CA 证书存在。回报：是否存在企业 CA 证书，以及证书是否未过期。"
    }
    default {
        $needsHuman = $false
        $humanDetail = $null
    }
}

# Step 5: Build recommended next action
$nextAction = ''
switch ($rootCause.Category) {
    '本地状态阻塞' {
        if ($allFindings.ContainsKey('merge_in_progress')) { $nextAction = '执行 git merge --abort 中止当前合并' }
        elseif ($allFindings.ContainsKey('rebase_in_progress')) { $nextAction = '执行 git rebase --abort 中止当前变基' }
        elseif ($allFindings.ContainsKey('detached_head')) { $nextAction = '执行 git checkout <branch-name> 切换到已有分支' }
        elseif ($allFindings.ContainsKey('no_upstream')) { $nextAction = '执行 git branch --set-upstream-to=origin/<branch> <branch> 设置 upstream' }
        else { $nextAction = '解决本地仓库状态问题后重试远程操作' }
    }
    'DNS 解析失败' { $nextAction = '检查 DNS 配置：1) 尝试 nslookup github.com；2) 如使用企业网络，联系 IT 确认 DNS 过滤策略；3) 可尝试修改 DNS 为 8.8.8.8 或 1.1.1.1' }
    '连接超时/拒绝' { $nextAction = '检查网络连通性：1) 确认是否有 VPN 或代理运行；2) 如使用 SSH 且端口 22 被阻，执行 git remote set-url origin https://... 切换为 HTTPS' }
    '认证失败' { $nextAction = '刷新 Git 凭据：1) 执行 git credential reject 清除旧凭据；2) 重新执行远程操作触发认证弹窗；3) 如使用 SSH，验证密钥已添加到 GitHub' }
    '授权不足' { $nextAction = '检查访问权限——需要人工在浏览器中验证 Token 权限和组织 SSO 状态（见 human_action_detail）' }
    '代理错误' { $nextAction = '修复代理配置：1) 检查 git config --global http.proxy 是否正确；2) 如不需要代理，执行 git config --global --unset http.proxy 移除代理；3) 检查 Windows 系统代理设置' }
    'TLS/SSL 错误' { $nextAction = '检查证书配置——需要人工在 Windows certmgr.msc 中验证证书链（见 human_action_detail）。临时绕过（风险操作）：git config --global http.sslVerify false' }
    '仓库策略拒绝' { $nextAction = '仓库策略限制——需要通过 PR 合并或请求管理员权限。具体操作见 human_action_detail。' }
    '仓库不存在' { $nextAction = '验证仓库存在性——需要人工在浏览器中确认仓库状态（见 human_action_detail）。如仓库已迁移，更新远程 URL：git remote set-url origin <new-url>' }
    '远程目标错误' {
        if ($allFindings.ContainsKey('no_remotes')) { $nextAction = '添加远程仓库：git remote add origin <repository-url>' }
        elseif ($allFindings.ContainsKey('url_malformed')) { $nextAction = '修正远程 URL：git remote set-url origin <correct-url>' }
        elseif ($allFindings.ContainsKey('upstream_gone')) { $nextAction = '远程分支已删除：执行 git fetch --prune 清理本地引用' }
        else { $nextAction = '检查并修正远程仓库配置后重试' }
    }
    default { $nextAction = '诊断未匹配到已知模式——请人工分析以上 evidence 输出，并将发现反馈给诊断系统' }
}

# Step 6: Build and output final JSON
$output = Build-StructuredOutput `
    -ProblemCategory $rootCause.Category `
    -Evidence $allEvidence `
    -LikelyCause $rootCause.Cause `
    -Confidence $rootCause.Confidence `
    -ActionsTaken $allActions `
    -RecommendedNextAction $nextAction `
    -HumanInteractionRequired $needsHuman `
    -HumanActionDetail $humanDetail

Write-Output $output
exit 0
