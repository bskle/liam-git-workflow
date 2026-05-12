# Liam Git Workflow Policy

This file is the canonical Git policy for the plugin.

## Branch Model

- `main`: production branch
- `dev`: default integration branch
- `feature/<scope>-<short-desc>`: new feature work
- `fix/<scope>-<short-desc>`: non-production bug fix
- `hotfix/<scope>-<short-desc>`: production emergency fix from `main`
- `release/<version>`: optional release prep branch
- `chore/<scope>-<short-desc>`: scripts, config, build, deployment work
- `docs/<scope>-<short-desc>`: documentation-only changes
- `refactor/<scope>-<short-desc>`: internal cleanup without intended behavior change

## Merge Hierarchy

- `feature/*` -> `dev`
- `fix/*` -> `dev`
- `chore/*` -> `dev`
- `docs/*` -> `dev`
- `refactor/*` -> `dev`
- `hotfix/*` -> `main`, then sync back to `dev`
- `dev` -> `main` only for release

Never merge `feature/*` or `fix/*` directly into `main`.

## Naming Rules

- all lower-case
- use hyphens, not spaces or underscores
- keep `scope` specific to a feature area or module

## Commit Rules

- use Conventional Commits
- write commit subjects in Chinese
- keep one clear change per commit
- prefer:
  - `feat`
  - `fix`
  - `docs`
  - `chore`
  - `refactor`
  - `test`
  - `build`
  - `ci`
  - `perf`
  - `revert`

## Sync Rules

- prefer `git pull --rebase`
- verify locally after conflict resolution
- do not force push unless explicitly authorized
- do not push directly to `main`

## PR Rules

PRs should include:

1. purpose and background
2. main changes
3. risk and impact
4. test evidence
5. rollback plan when relevant

Prefer `Squash and merge`.

## Hotfix Rules

1. branch from `main`
2. use `hotfix/*`
3. add minimum regression coverage
4. merge back to `main`
5. tag patch release on `main`
6. sync fix back to `dev`

## Release Rules

- `main` stays releasable
- release tags only on `main`
- use `vMAJOR.MINOR.PATCH`
- include release notes

## Recommended Git Config

```bash
git config --global pull.rebase true
git config --global rebase.autoStash true
git config --global fetch.prune true
git config --global core.autocrlf input
```

