Set-StrictMode -Version Latest

function Resolve-LiamGitWorkflowRepoRoot {
    param(
        [string]$RepoRoot,
        [string]$ScriptRoot
    )

    if ($RepoRoot) {
        return (Resolve-Path -LiteralPath $RepoRoot).Path
    }

    return (Resolve-Path -LiteralPath (Split-Path -Parent $ScriptRoot)).Path
}

function Get-LiamGitWorkflowVersion {
    param([string]$RepoRoot)

    $versionPath = Join-Path $RepoRoot 'VERSION'
    if (-not (Test-Path -LiteralPath $versionPath)) {
        throw "VERSION file not found: $versionPath"
    }

    return (Get-Content -LiteralPath $versionPath -Raw).Trim()
}

function Ensure-Directory {
    param([string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

function Reset-Path {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force
    }
}

function Copy-DirectoryTree {
    param(
        [string]$Source,
        [string]$Destination
    )

    Reset-Path -Path $Destination
    Ensure-Directory -Path (Split-Path -Parent $Destination)
    Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
}

function Copy-FileWithReplacements {
    param(
        [string]$Source,
        [string]$Destination,
        [hashtable]$Replacements
    )

    Ensure-Directory -Path (Split-Path -Parent $Destination)
    $content = Get-Content -LiteralPath $Source -Raw
    foreach ($key in $Replacements.Keys) {
        $content = $content.Replace($key, $Replacements[$key])
    }

    Set-Content -LiteralPath $Destination -Value $content -Encoding UTF8
}

function Convert-ToForwardSlashPath {
    param([string]$Path)

    return $Path -replace '\\', '/'
}

function Install-LiamGitWorkflowCodex {
    param(
        [string]$RepoRoot,
        [string]$CodexHome
    )

    $skillsSourceRoot = Join-Path $RepoRoot 'skills'
    $referencesSourceRoot = Join-Path $RepoRoot 'references'
    $scriptsSourceRoot = Join-Path $RepoRoot 'scripts'
    $hooksSourceRoot = Join-Path $RepoRoot 'hooks'
    $skillsTargetRoot = Join-Path $CodexHome 'skills'
    $supportTargetRoot = Join-Path $skillsTargetRoot 'liam-git-workflow-support'

    Ensure-Directory -Path $skillsTargetRoot
    Copy-DirectoryTree -Source $referencesSourceRoot -Destination (Join-Path $supportTargetRoot 'references')
    Copy-DirectoryTree -Source $scriptsSourceRoot -Destination (Join-Path $supportTargetRoot 'scripts')
    Copy-DirectoryTree -Source $hooksSourceRoot -Destination (Join-Path $supportTargetRoot 'hooks')

    $skillDirs = Get-ChildItem -LiteralPath $skillsSourceRoot -Directory |
        Where-Object { $_.Name -like 'liam-git-workflow*' } |
        Sort-Object Name

    foreach ($skillDir in $skillDirs) {
        $targetDir = Join-Path $skillsTargetRoot $skillDir.Name
        Reset-Path -Path $targetDir
        Ensure-Directory -Path $targetDir

        foreach ($sourceFile in Get-ChildItem -LiteralPath $skillDir.FullName -File) {
            $targetFile = Join-Path $targetDir $sourceFile.Name
            if ($sourceFile.Name -eq 'SKILL.md') {
                $content = Get-Content -LiteralPath $sourceFile.FullName -Raw
                $content = $content.Replace('../../references/', '../liam-git-workflow-support/references/')
                $content = $content.Replace('../../scripts/', '../liam-git-workflow-support/scripts/')
                Set-Content -LiteralPath $targetFile -Value $content -Encoding UTF8
            }
            else {
                Copy-Item -LiteralPath $sourceFile.FullName -Destination $targetFile -Force
            }
        }
    }
}

function Install-LiamGitWorkflowClaude {
    param(
        [string]$RepoRoot,
        [string]$ClaudeHome,
        [string]$Version
    )

    $commandsSourceRoot = Join-Path $RepoRoot 'claude\commands'
    $referencesSourceRoot = Join-Path $RepoRoot 'references'
    $scriptsSourceRoot = Join-Path $RepoRoot 'scripts'
    $hooksSourceRoot = Join-Path $RepoRoot 'hooks'
    $targetRoot = Join-Path $ClaudeHome '.claude\commands\liam-git-workflow'
    $targetReferencesRoot = Join-Path $targetRoot 'references'
    $targetScriptsRoot = Join-Path $targetRoot 'scripts'
    $targetHooksRoot = Join-Path $targetRoot 'hooks'

    Ensure-Directory -Path $targetRoot
    Copy-DirectoryTree -Source $referencesSourceRoot -Destination $targetReferencesRoot
    Copy-DirectoryTree -Source $scriptsSourceRoot -Destination $targetScriptsRoot
    Copy-DirectoryTree -Source $hooksSourceRoot -Destination $targetHooksRoot

    $referencePath = Convert-ToForwardSlashPath -Path $targetReferencesRoot
    $scriptPath = Convert-ToForwardSlashPath -Path $targetScriptsRoot
    $repoPath = Convert-ToForwardSlashPath -Path $RepoRoot

    $replacements = @{
        '{{REFERENCES_ROOT}}' = $referencePath
        '{{SCRIPTS_ROOT}}' = $scriptPath
        '{{REPO_ROOT}}' = $repoPath
        '{{VERSION}}' = $Version
    }

    foreach ($commandFile in Get-ChildItem -LiteralPath $commandsSourceRoot -File -Filter '*.md') {
        Copy-FileWithReplacements -Source $commandFile.FullName -Destination (Join-Path $targetRoot $commandFile.Name) -Replacements $replacements
    }
}

function Write-LiamGitWorkflowInstallMetadata {
    param(
        [string]$RepoRoot,
        [string]$CodexHome,
        [string]$ClaudeHome,
        [string]$Version,
        [bool]$InstalledCodex,
        [bool]$InstalledClaude
    )

    $metadataRoot = Join-Path $ClaudeHome '.liam-git-workflow'
    Ensure-Directory -Path $metadataRoot

    $payload = [ordered]@{
        version = $Version
        repoRoot = $RepoRoot
        codexHome = $CodexHome
        claudeHome = $ClaudeHome
        installedCodex = $InstalledCodex
        installedClaude = $InstalledClaude
        installedAt = (Get-Date).ToString('o')
    }

    $json = $payload | ConvertTo-Json -Depth 4
    Set-Content -LiteralPath (Join-Path $metadataRoot 'install.json') -Value $json -Encoding UTF8
}
