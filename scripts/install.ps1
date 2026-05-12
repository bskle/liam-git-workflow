param(
    [string]$RepoRoot,
    [string]$CodexHome = $(if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }),
    [string]$ClaudeHome = $env:USERPROFILE,
    [switch]$SkipCodex,
    [switch]$SkipClaude
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

$resolvedRepoRoot = Resolve-LiamGitWorkflowRepoRoot -RepoRoot $RepoRoot -ScriptRoot $PSScriptRoot
$version = Get-LiamGitWorkflowVersion -RepoRoot $resolvedRepoRoot

if (-not $SkipCodex) {
    Install-LiamGitWorkflowCodex -RepoRoot $resolvedRepoRoot -CodexHome $CodexHome
}

if (-not $SkipClaude) {
    Install-LiamGitWorkflowClaude -RepoRoot $resolvedRepoRoot -ClaudeHome $ClaudeHome -Version $version
}

Write-LiamGitWorkflowInstallMetadata `
    -RepoRoot $resolvedRepoRoot `
    -CodexHome $CodexHome `
    -ClaudeHome $ClaudeHome `
    -Version $version `
    -InstalledCodex (-not $SkipCodex) `
    -InstalledClaude (-not $SkipClaude)

Write-Host "Installed Liam Git Workflow $version"
