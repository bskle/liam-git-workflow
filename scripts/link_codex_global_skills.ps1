param(
  [string]$CodexHome = "$env:USERPROFILE\.codex",
  [string]$RepoRoot
)

$ErrorActionPreference = "Stop"

$installScript = Join-Path $PSScriptRoot "install.ps1"

& powershell -ExecutionPolicy Bypass -File $installScript `
  -RepoRoot $RepoRoot `
  -CodexHome $CodexHome `
  -SkipClaude

if ($LASTEXITCODE -ne 0) {
  throw "Codex install failed."
}

Write-Host "Codex skills installed via install.ps1"
