param(
    [string]$RepoRoot,
    [string]$CodexSkillsHome = "$env:USERPROFILE\.agents\skills",
    [switch]$SkipCodex,
    [switch]$SkipClaude,
    [switch]$CleanLegacy
)

$ErrorActionPreference = "Stop"

# Dot-source shared utilities (Resolve-LiamGitWorkflowRepoRoot, Get-LiamGitWorkflowVersion,
# Ensure-Directory, Reset-Path, Write-LiamGitWorkflowInstallMetadata)
. (Join-Path $PSScriptRoot "common.ps1")

$resolvedRoot = Resolve-LiamGitWorkflowRepoRoot -RepoRoot $RepoRoot -ScriptRoot $PSScriptRoot
$version = Get-LiamGitWorkflowVersion -RepoRoot $resolvedRoot

# ── Codex: 目录 junction (mklink /J) 从 ~/.agents/skills/liam-git-workflow → repo/skills/ ──
if (-not $SkipCodex) {
    $codexTarget = Join-Path $CodexSkillsHome "liam-git-workflow"
    $codexSource = Join-Path $resolvedRoot "skills"

    if (-not (Test-Path -LiteralPath $codexSource)) {
        throw "Skills source directory not found: $codexSource"
    }

    Ensure-Directory -Path $CodexSkillsHome

    # 如果目标已存在（旧 junction 或遗留目录），先删除
    if (Test-Path -LiteralPath $codexTarget) {
        Write-Host "Removing existing install at $codexTarget"
        cmd /c rmdir "$codexTarget" 2>$null
        if (Test-Path -LiteralPath $codexTarget) {
            Remove-Item -LiteralPath $codexTarget -Recurse -Force
        }
    }

    # 使用 cmd /c mklink /J（PowerShell New-Item -ItemType Junction 在 Windows 10+ 也可用，
    # 但 mklink /J 在 PowerShell 中需通过 cmd 调用）
    $mklinkCmd = "mklink /J `"$codexTarget`" `"$codexSource`""
    cmd /c $mklinkCmd
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to create directory junction: $codexTarget -> $codexSource (exit code $LASTEXITCODE)"
    }

    # 验证 junction 创建成功
    $junctionTarget = (Get-Item -LiteralPath $codexTarget -Force).Target
    if (-not $junctionTarget) {
        throw "Junction created but Target property is empty: $codexTarget"
    }
    Write-Host "Codex: symlinked $codexTarget -> $codexSource"
}

# ── Claude Code: 插件目录即为仓库本身; 提示用户使用 /plugin install ──
if (-not $SkipClaude) {
    Write-Host "Claude Code: 仓库已配置为插件目录。使用以下任一方式安装:"
    Write-Host "  方式 1: 在 Claude Code 会话中运行 /plugin install `"$resolvedRoot`""
    Write-Host "  方式 2: 启动时指定插件目录 claude --plugin-dir `"$resolvedRoot`""
    Write-Host ""
    Write-Host "安装后，skills/ 中的技能将通过 Skill tool 自动可用。"
}

# ── CleanLegacy: 清理旧版文件复制安装产物 ──
if ($CleanLegacy) {
    Write-Host "Cleaning legacy install artifacts..."

    # 旧 Codex 文件复制产物: ~/.codex/skills/liam-git-workflow*
    $legacyCodexSkills = Join-Path $env:USERPROFILE ".codex\skills"
    if (Test-Path -LiteralPath $legacyCodexSkills) {
        $legacyDirs = Get-ChildItem -LiteralPath $legacyCodexSkills -Directory -Filter "liam-git-workflow*" -ErrorAction SilentlyContinue
        foreach ($dir in $legacyDirs) {
            Write-Host "  Removing legacy Codex skills: $($dir.FullName)"
            Remove-Item -LiteralPath $dir.FullName -Recurse -Force
        }
    }

    # 旧 Claude Code 命令产物: ~/.claude/commands/liam-git-workflow/
    $legacyClaudeCommands = Join-Path $env:USERPROFILE ".claude\commands\liam-git-workflow"
    if (Test-Path -LiteralPath $legacyClaudeCommands) {
        Write-Host "  Removing legacy Claude commands: $legacyClaudeCommands"
        Remove-Item -LiteralPath $legacyClaudeCommands -Recurse -Force
    }

    # 旧 Codex symlink: ~/.agents/skills/ 中可能存在的旧 junction
    $legacyAgentsSkills = Join-Path $env:USERPROFILE ".agents\skills\liam-git-workflow"
    if (Test-Path -LiteralPath $legacyAgentsSkills) {
        $item = Get-Item -LiteralPath $legacyAgentsSkills -Force
        if ($item.LinkType -eq "Junction" -or $item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
            Write-Host "  Removing old junction: $legacyAgentsSkills"
            cmd /c rmdir "$legacyAgentsSkills" 2>$null
            if (Test-Path -LiteralPath $legacyAgentsSkills) {
                Remove-Item -LiteralPath $legacyAgentsSkills -Recurse -Force
            }
        }
    }

    Write-Host "Legacy cleanup complete."
}

# ── 写入安装元数据 ──
Write-LiamGitWorkflowInstallMetadata 
    -RepoRoot $resolvedRoot 
    -InstalledCodex (-not $SkipCodex) 
    -InstalledClaude (-not $SkipClaude) 
    -Version $version

Write-Host ""
Write-Host "Liam Git Workflow $version 安装完成"
Write-Host "  Codex: $(if (-not $SkipCodex) { `"已安装 (symlink)`" } else { `"已跳过`" })"
Write-Host "  Claude Code: $(if (-not $SkipClaude) { `"已配置 (使用 /plugin install 完成安装)`" } else { `"已跳过`" })"
if ($CleanLegacy) {
    Write-Host "  旧安装产物: 已清理"
}