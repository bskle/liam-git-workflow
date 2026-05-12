param()

$ErrorActionPreference = "Stop"

$expected = [ordered]@{
  "pull.rebase" = "true"
  "rebase.autoStash" = "true"
  "fetch.prune" = "true"
  "core.autocrlf" = "input"
}

$rows = foreach ($key in $expected.Keys) {
  $current = git config --global $key 2>$null
  if (-not $current) {
    $current = "<unset>"
  }

  $match = ($current -eq $expected[$key]).ToString().ToLowerInvariant()

  [pscustomobject]@{
    Key = $key
    Current = $current
    Expected = $expected[$key]
    Match = $match
  }
}

$rows | Format-Table -AutoSize
