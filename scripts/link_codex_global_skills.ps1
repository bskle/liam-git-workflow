param(
  [string]$CodexHome = "$env:USERPROFILE\.codex",
  [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Write-Step {
  param([string]$Message)
  Write-Host "==> $Message"
}

function Test-ReparsePoint {
  param([string]$Path)

  if (-not (Test-Path -LiteralPath $Path)) {
    return $false
  }

  $item = Get-Item -LiteralPath $Path -Force
  return [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
}

function Invoke-MoveToBackup {
  param(
    [string]$Path,
    [string]$BackupRoot
  )

  if (-not (Test-Path -LiteralPath $Path)) {
    return
  }

  $name = Split-Path -Leaf $Path
  $destination = Join-Path $BackupRoot $name
  Write-Step "Backing up $Path -> $destination"
  if (-not $DryRun) {
    Move-Item -LiteralPath $Path -Destination $destination
  }
}

function Invoke-NewJunction {
  param(
    [string]$LinkPath,
    [string]$TargetPath
  )

  Write-Step "Linking $LinkPath -> $TargetPath"
  if (-not $DryRun) {
    New-Item -ItemType Junction -Path $LinkPath -Target $TargetPath | Out-Null
  }
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$skillsSourceRoot = Join-Path $repoRoot "skills"
$referencesSource = Join-Path $repoRoot "references"
$skillsTargetRoot = Join-Path $CodexHome "skills"
$referencesTarget = Join-Path $CodexHome "references"

if (-not (Test-Path -LiteralPath $skillsTargetRoot)) {
  throw "Codex skills directory not found: $skillsTargetRoot"
}

$skillDirs = Get-ChildItem -LiteralPath $skillsSourceRoot -Directory |
  Where-Object { $_.Name -like "liam-git-workflow*" } |
  Sort-Object Name

if (-not $skillDirs) {
  throw "No liam-git-workflow skill directories found under $skillsSourceRoot"
}

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRoot = Join-Path $CodexHome "backups\liam-git-workflow-$timestamp"

Write-Step "Repo root: $repoRoot"
Write-Step "Codex home: $CodexHome"

if (Test-Path -LiteralPath $referencesTarget) {
  if (-not (Test-ReparsePoint -Path $referencesTarget)) {
    throw "Refusing to replace non-link path: $referencesTarget"
  }

  $currentTarget = (Get-Item -LiteralPath $referencesTarget -Force).Target
  if ($currentTarget -and ($currentTarget -ne $referencesSource)) {
    throw "Refusing to replace $referencesTarget because it points to $currentTarget"
  }
} else {
  Write-Step "Preparing shared references link at $referencesTarget"
  if (-not $DryRun) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $backupRoot) -Force | Out-Null
  }
  Invoke-NewJunction -LinkPath $referencesTarget -TargetPath $referencesSource
}

foreach ($skillDir in $skillDirs) {
  $targetPath = Join-Path $skillsTargetRoot $skillDir.Name

  if (Test-Path -LiteralPath $targetPath) {
    if (Test-ReparsePoint -Path $targetPath) {
      $currentTarget = (Get-Item -LiteralPath $targetPath -Force).Target
      if ($currentTarget -eq $skillDir.FullName) {
        Write-Step "Link already up to date: $targetPath"
        continue
      }

      throw "Refusing to replace existing link $targetPath because it points to $currentTarget"
    }

    if (-not (Test-Path -LiteralPath $backupRoot)) {
      Write-Step "Creating backup directory $backupRoot"
      if (-not $DryRun) {
        New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
      }
    }

    Invoke-MoveToBackup -Path $targetPath -BackupRoot $backupRoot
  }

  Invoke-NewJunction -LinkPath $targetPath -TargetPath $skillDir.FullName
}

Write-Step "Done"
