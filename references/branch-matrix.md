# Branch Matrix

## Quick Decision Table

| Situation | Branch Type | Base | Merge Target |
|---|---|---|---|
| New feature | `feature/*` | `dev` | `dev` |
| Pre-release bug | `fix/*` | `dev` | `dev` |
| Production bug | `hotfix/*` | `main` | `main`, then `dev` |
| Docs only | `docs/*` | `dev` | `dev` |
| Build or deploy change | `chore/*` | `dev` | `dev` |
| Internal cleanup | `refactor/*` | `dev` | `dev` |
| Release prep | `release/*` | `dev` | `main` |

## Classification Rules

- If the problem is already in production, choose `hotfix/*`
- If the change introduces user-facing capability, choose `feature/*`
- If the change repairs behavior not yet released, choose `fix/*`
- If the change is mostly scripts, CI, deployment, or config, choose `chore/*`
- If the change is documentation only, choose `docs/*`
- If the change keeps behavior stable but reorganizes code, choose `refactor/*`

## Naming Pattern

Use:

```text
<type>/<scope>-<short-desc>
```

Examples:

- `feature/translator-batch-import`
- `fix/login-timeout`
- `hotfix/login-network-error`
- `chore/deploy-log-maintenance`
- `docs/api-upstream-contract`

