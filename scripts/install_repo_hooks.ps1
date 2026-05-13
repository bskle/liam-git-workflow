param(
    [string]$RepoRoot
)

$ErrorActionPreference = 'Stop'

. (Join-Path $PSScriptRoot 'common.ps1')

$resolvedRepoRoot = if ($RepoRoot) {
    (Resolve-Path -LiteralPath $RepoRoot).Path
}
else {
    (Get-Location).Path
}

$gitDir = Join-Path $resolvedRepoRoot '.git'
if (-not (Test-Path -LiteralPath $gitDir)) {
    throw "Target repository not found: $resolvedRepoRoot"
}

$supportRoot = Split-Path -Parent $PSScriptRoot
$bundledHooksRoot = Join-Path $supportRoot 'hooks'
$bundledHookPath = Join-Path $bundledHooksRoot 'commit-msg'
$validatorSourcePath = Join-Path $PSScriptRoot 'validate_commit_message.ps1'

if (-not (Test-Path -LiteralPath $bundledHookPath)) {
    throw "Bundled commit-msg hook not found: $bundledHookPath"
}

if (-not (Test-Path -LiteralPath $validatorSourcePath)) {
    throw "Bundled validator script not found: $validatorSourcePath"
}

$targetHooksRoot = Join-Path $resolvedRepoRoot '.githooks'
Ensure-Directory -Path $targetHooksRoot

Copy-Item -LiteralPath $bundledHookPath -Destination (Join-Path $targetHooksRoot 'commit-msg') -Force
Copy-Item -LiteralPath $validatorSourcePath -Destination (Join-Path $targetHooksRoot 'validate_commit_message.ps1') -Force

& git -C $resolvedRepoRoot config core.hooksPath .githooks
if ($LASTEXITCODE -ne 0) {
    throw "Failed to configure core.hooksPath for $resolvedRepoRoot"
}

Write-Host "Installed Liam Git Workflow hooks into $targetHooksRoot"
