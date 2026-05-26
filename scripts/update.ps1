param(
    [string]$RepoRoot,
    [switch]$SkipCodex,
    [switch]$SkipClaude,
    [switch]$PullLatest
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

$resolvedRepoRoot = Resolve-LiamGitWorkflowRepoRoot -RepoRoot $RepoRoot -ScriptRoot $PSScriptRoot

if ($PullLatest) {
    $statusOutput = git -C $resolvedRepoRoot status --porcelain
    if ($LASTEXITCODE -ne 0) {
        throw 'Unable to inspect repository status before update.'
    }

    if ($statusOutput) {
        throw 'Refusing to pull because the repository has local changes. Commit or stash them first.'
    }

    git -C $resolvedRepoRoot pull --rebase
    if ($LASTEXITCODE -ne 0) {
        throw 'git pull --rebase failed during update.'
    }
}

$installArgs = @(
    '-ExecutionPolicy', 'Bypass',
    '-File', (Join-Path $PSScriptRoot 'install.ps1'),
    '-RepoRoot', $resolvedRepoRoot
)

if ($SkipCodex) {
    $installArgs += '-SkipCodex'
}

if ($SkipClaude) {
    $installArgs += '-SkipClaude'
}

& powershell @installArgs

if ($LASTEXITCODE -ne 0) {
    throw 'install.ps1 failed during update.'
}

Write-Host 'Updated Liam Git Workflow'
