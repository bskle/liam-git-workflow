---
name: gw-sync
description: Decide how the current work branch should sync with its base branch in Liam's workflow. Use when the user wants to pull latest changes, rebase onto dev or main, resolve branch drift, or asks how to sync a feature, fix, or hotfix branch safely.
---

# Sync Branch

Read first:

- `../../references/policy.md`
- `../../references/branch-matrix.md`
- `../../references/remote-diagnostics.md`

## Workflow

1. Infer the current branch family
2. Choose the expected base branch
3. Prefer `git pull --rebase` semantics
4. Warn about uncommitted changes and conflict handling; if a remote operation (pull/fetch) fails, stop and route to the remote diagnostic capability before retrying

## Output

Provide:

- expected upstream branch
- recommended sync approach
- conflict caution
- optional command sequence

## Troubleshooting

When a sync operation fails with a Git remote error (push/pull/fetch), do not retry the same command immediately. Instead:

1. Route to `gw-diagnose` for structured five-layer diagnosis
2. Apply the recommended fix from the diagnostic output (problem_category, likely_cause, recommended_next_action)
3. Retry the sync operation only after the root cause has been addressed

Common remote failures during sync include:
- Authentication failures (expired credentials, wrong SSH key) -- 第 3 层
- DNS resolution failures (corporate DNS filtering, hostname typos) -- 第 4 层
- Connection timeouts (firewall blocking, proxy misconfiguration) -- 第 4 层
- Upstream branch gone or renamed -- 第 2 层
- Protected branch or organization policy rejection -- 第 5 层

See `references/remote-diagnostics.md` for the complete signal-to-cause mapping and standard repair actions.

