$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$validatorScript = Join-Path $repoRoot 'scripts\validate_commit_message.ps1'
$commitSkill = Join-Path $repoRoot 'skills\liam-git-workflow-commit\SKILL.md'
$rootSkill = Join-Path $repoRoot 'skills\liam-git-workflow\SKILL.md'
$hookTemplatePath = Join-Path $repoRoot 'hooks\commit-msg'

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

function Invoke-Validator {
    param([string]$MessageFile)

    $global:LASTEXITCODE = 0

    try {
        & powershell -ExecutionPolicy Bypass -File $validatorScript -CommitMessageFile $MessageFile *> $null
    }
    catch {
        if ($global:LASTEXITCODE -eq 0) {
            throw
        }
    }

    return $global:LASTEXITCODE
}

Assert-PathExists $validatorScript 'Commit message validator script should exist.'
Assert-PathExists $hookTemplatePath 'commit-msg hook template should exist.'

$commitSkillContent = Get-Content -LiteralPath $commitSkill -Raw
$rootSkillContent = Get-Content -LiteralPath $rootSkill -Raw

Assert-Contains $rootSkillContent 'subject must be Chinese' 'Root skill should repeat the Chinese subject rule.'
Assert-Contains $commitSkillContent 'Read the staged diff before drafting messages.' 'Commit skill should require staged diff inspection.'
Assert-Contains $commitSkillContent 'Stop and regenerate if the final subject does not contain Chinese characters.' 'Commit skill should stop invalid commit messages before execution.'

$workspaceRoot = Join-Path ([System.IO.Path]::GetTempPath()) ('liam-git-workflow-commit-msg-' + [guid]::NewGuid().ToString('N'))
$englishMessagePath = Join-Path $workspaceRoot 'english.txt'
$chineseMessagePath = Join-Path $workspaceRoot 'chinese.txt'

try {
    New-Item -ItemType Directory -Path $workspaceRoot -Force | Out-Null

    Set-Content -LiteralPath $englishMessagePath -Value 'fix(tooling): enforce english subject' -Encoding UTF8
    if ((Invoke-Validator -MessageFile $englishMessagePath) -eq 0) {
        throw 'Validator should reject an English-only commit subject.'
    }

    Set-Content -LiteralPath $chineseMessagePath -Value 'fix(tooling): 强制中文提交主题' -Encoding UTF8
    if ((Invoke-Validator -MessageFile $chineseMessagePath) -ne 0) {
        throw 'Validator should accept a Chinese commit subject.'
    }
}
finally {
    if (Test-Path -LiteralPath $workspaceRoot) {
        Remove-Item -LiteralPath $workspaceRoot -Recurse -Force
    }
}
