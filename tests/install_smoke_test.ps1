$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$installScript = Join-Path $repoRoot 'scripts\install.ps1'
$updateScript = Join-Path $repoRoot 'scripts\update.ps1'
$versionFile = Join-Path $repoRoot 'VERSION'
$claudeCommandsRoot = Join-Path $repoRoot 'claude\commands'

function Assert-True {
    param(
        [bool]$Condition,
        [string]$Message
    )

    if (-not $Condition) {
        throw $Message
    }
}

function Assert-PathExists {
    param(
        [string]$Path,
        [string]$Message
    )

    Assert-True (Test-Path -LiteralPath $Path) $Message
}

function Assert-Contains {
    param(
        [string]$Value,
        [string]$ExpectedSubstring,
        [string]$Message
    )

    Assert-True ($Value.Contains($ExpectedSubstring)) $Message
}

function Assert-NotContains {
    param(
        [string]$Value,
        [string]$UnexpectedSubstring,
        [string]$Message
    )

    Assert-True (-not $Value.Contains($UnexpectedSubstring)) $Message
}

Assert-PathExists $installScript 'install.ps1 should exist.'
Assert-PathExists $updateScript 'update.ps1 should exist.'
Assert-PathExists $versionFile 'VERSION file should exist.'
Assert-PathExists $claudeCommandsRoot 'Claude commands source directory should exist.'

$workspaceRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('liam-git-workflow-test-' + [guid]::NewGuid().ToString('N'))
$codexHome = Join-Path $workspaceRoot 'codex-home'
$claudeHome = Join-Path $workspaceRoot 'claude-home'
$codexSkillsRoot = Join-Path $codexHome 'skills'
$codexSupportRoot = Join-Path $codexSkillsRoot 'liam-git-workflow-support'
$claudeCommandsTarget = Join-Path $claudeHome '.claude\commands\liam-git-workflow'
$targetRepoRoot = Join-Path $workspaceRoot 'target-repo'

try {
    New-Item -ItemType Directory -Path $codexSkillsRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $claudeHome -Force | Out-Null

    & powershell -ExecutionPolicy Bypass -File $installScript `
        -RepoRoot $repoRoot `
        -CodexHome $codexHome `
        -ClaudeHome $claudeHome | Out-Null

    Assert-PathExists (Join-Path $codexSkillsRoot 'liam-git-workflow') 'Codex root skill should be installed.'
    Assert-PathExists (Join-Path $codexSkillsRoot 'liam-git-workflow-commit') 'Codex commit skill should be installed.'
    Assert-PathExists (Join-Path $codexSupportRoot 'references\policy.md') 'Codex support references should be installed.'
    Assert-PathExists (Join-Path $codexSupportRoot 'scripts\audit_git_config.ps1') 'Codex support scripts should be installed.'
    Assert-PathExists (Join-Path $codexSupportRoot 'scripts\validate_commit_message.ps1') 'Codex support validator script should be installed.'
    Assert-PathExists (Join-Path $codexSupportRoot 'hooks\commit-msg') 'Codex support hook template should be installed.'
    Assert-PathExists (Join-Path $claudeCommandsTarget 'liam-git-workflow.md') 'Claude root command should be installed.'
    Assert-PathExists (Join-Path $claudeCommandsTarget 'liam-git-workflow-commit.md') 'Claude commit command should be installed.'
    Assert-PathExists (Join-Path $claudeCommandsTarget 'scripts\validate_commit_message.ps1') 'Claude support validator script should be installed.'
    Assert-PathExists (Join-Path $claudeCommandsTarget 'hooks\commit-msg') 'Claude support hook template should be installed.'
    Assert-PathExists (Join-Path $claudeHome '.liam-git-workflow\install.json') 'Install metadata should exist.'

    $installedSkill = Get-Content -LiteralPath (Join-Path $codexSkillsRoot 'liam-git-workflow\SKILL.md') -Raw
    Assert-Contains $installedSkill '../liam-git-workflow-support/references/policy.md' 'Installed Codex skill should point to support references.'
    Assert-NotContains $installedSkill '../../references/' 'Installed Codex skill should not keep repo-only reference paths.'

    $installedClaudeCommand = Get-Content -LiteralPath (Join-Path $claudeCommandsTarget 'liam-git-workflow.md') -Raw
    Assert-NotContains $installedClaudeCommand '{{REFERENCES_ROOT}}' 'Installed Claude command should not keep template placeholders.'
    Assert-Contains $installedClaudeCommand '@' 'Installed Claude command should still contain file references.'

    & powershell -ExecutionPolicy Bypass -File $updateScript `
        -RepoRoot $repoRoot `
        -CodexHome $codexHome `
        -ClaudeHome $claudeHome | Out-Null

    Assert-PathExists (Join-Path $claudeCommandsTarget 'liam-git-workflow-sync-policy.md') 'Update should preserve Claude commands.'

    New-Item -ItemType Directory -Path $targetRepoRoot -Force | Out-Null
    & git -C $targetRepoRoot init | Out-Null

    $installedHookScript = Join-Path $codexSupportRoot 'scripts\install_repo_hooks.ps1'
    & powershell -ExecutionPolicy Bypass -File $installedHookScript -RepoRoot $targetRepoRoot | Out-Null

    Assert-PathExists (Join-Path $targetRepoRoot '.githooks\commit-msg') 'Installed hook script should materialize commit-msg into the target repo.'
    Assert-PathExists (Join-Path $targetRepoRoot '.githooks\validate_commit_message.ps1') 'Installed hook script should copy the validator into the target repo.'

    $hooksPath = (& git -C $targetRepoRoot config --get core.hooksPath).Trim()
    Assert-True ($hooksPath -eq '.githooks') 'Installed hook script should point core.hooksPath to .githooks.'
}
finally {
    if (Test-Path -LiteralPath $workspaceRoot) {
        Remove-Item -LiteralPath $workspaceRoot -Recurse -Force
    }
}
