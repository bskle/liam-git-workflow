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

# === Task 2 will append Layer 4-5 + Signal Mapping + Output Builder + Main Flow from here ===
