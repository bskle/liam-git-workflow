# Liam Git Workflow

Personal Git workflow plugin for Claude Code and Codex — branch management, Chinese Conventional Commits, sync strategies, and remote diagnostics.

## Installation

### Claude Code

```bash
claude plugin marketplace add bskle/liam-git-workflow
claude plugin install liam-git-workflow@liam-git-workflow
```

### Codex

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install.ps1 -SkipClaude
```

## Updating

### Claude Code

```bash
claude plugin marketplace update liam-git-workflow
claude plugin update liam-git-workflow@liam-git-workflow
```

### Codex

```bash
git -C <仓库路径> pull --rebase
```

## What's Inside

**Branch Management**
- **gw-create-branch** — Create branch from correct base with proper naming
- **gw-finish** — Complete branch work and prepare next Git action

**Commit & Sync**
- **gw-commit** — Draft Chinese Conventional Commits
- **gw-sync** — Sync working branch to dev or main
- **gw-sync-policy** — Audit local Git config against policy

**Operations**
- **gw-hotfix** — Production emergency fix workflow
- **gw-release** — Tag and merge dev into main
- **gw-diagnose** — Structured remote operation failure diagnosis

**Meta**
- **gw** — Natural-language routing entrypoint
- **gw-help** — List all available skills
- **gw-bootstrap** — Skill discovery as slash commands

## Rules

All Git rules are defined in `references/`:

- [policy.md](references/policy.md) — Branch model and merge hierarchy
- [commit-rules.md](references/commit-rules.md) — Conventional Commit format (Chinese subject required)
- [branch-matrix.md](references/branch-matrix.md) — Branch type decision rules
- [pr-rules.md](references/pr-rules.md) — PR requirements and review process
- [scenarios.md](references/scenarios.md) — Common workflow examples

## Commit Hook (Optional)

Enforce commit message format in target repos:

```powershell
powershell -ExecutionPolicy Bypass -File <install-path>\scripts\install_repo_hooks.ps1 -RepoRoot .
```

## License

MIT — see [LICENSE](LICENSE)
