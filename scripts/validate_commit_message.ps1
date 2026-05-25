param(
    [Parameter(Mandatory = $true)]
    [string]$CommitMessageFile
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $CommitMessageFile)) {
    throw "Commit message file not found: $CommitMessageFile"
}

$message = (Get-Content -LiteralPath $CommitMessageFile -Raw).Trim()

if (-not $message) {
    Write-Error 'Commit message cannot be empty.'
    exit 1
}

$pattern = '^(feat|fix|docs|chore|refactor|test|build|ci|perf|revert)\(([a-z][a-z0-9-]*)\):\s+(.+)$'
$match = [regex]::Match($message, $pattern)

if (-not $match.Success) {
    Write-Error 'Commit message must match <type>(<scope>): <subject>.'
    exit 1
}

$subject = $match.Groups[3].Value.Trim()

if (-not [regex]::IsMatch($subject, '\p{IsCJKUnifiedIdeographs}')) {
    Write-Error 'Commit subject must contain Chinese characters.'
    exit 1
}

exit 0
