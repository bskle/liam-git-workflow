param(
  [string]$RepoRoot,
  [string]$CodexSkillsHome = "$env:USERPROFILE\.agents\skills"
)

$ErrorActionPreference = "Stop"

$installScript = Join-Path $PSScriptRoot "install.ps1"

$installArgs = @(
    '-ExecutionPolicy', 'Bypass',
    '-File', $installScript,
    '-SkipClaude'
)

if ($RepoRoot) {
    $installArgs += '-RepoRoot'
    $installArgs += $RepoRoot
}

if ($CodexSkillsHome -ne "$env:USERPROFILE\.agents\skills") {
    $installArgs += '-CodexSkillsHome'
    $installArgs += $CodexSkillsHome
}

& powershell @installArgs

if ($LASTEXITCODE -ne 0) {
  throw "Codex install failed."
}

Write-Host "Codex skills installed via symlink"
