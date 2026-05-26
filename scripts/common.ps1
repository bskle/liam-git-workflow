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

function Write-LiamGitWorkflowInstallMetadata {
    param(
        [string]$RepoRoot,
        [string]$Version,
        [bool]$InstalledCodex,
        [bool]$InstalledClaude
    )

    $metadataRoot = Join-Path $env:USERPROFILE '.liam-git-workflow'
    Ensure-Directory -Path $metadataRoot

    $payload = [ordered]@{
        version = $Version
        repoRoot = $RepoRoot
        installedCodex = $InstalledCodex
        installedClaude = $InstalledClaude
        installModel = if ($InstalledCodex) { 'symlink' } else { 'plugin-manifest' }
        installedAt = (Get-Date).ToString('o')
    }

    $json = $payload | ConvertTo-Json -Depth 4
    Set-Content -LiteralPath (Join-Path $metadataRoot 'install.json') -Value $json -Encoding UTF8
}
