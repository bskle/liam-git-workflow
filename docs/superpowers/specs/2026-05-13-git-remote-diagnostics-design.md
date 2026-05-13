# Git Remote Diagnostics Design

Date: 2026-05-13
Status: Approved for planning
Scope: Liam Git Workflow plugin

## 1. Goal

Add a reusable Git remote diagnostics capability to the existing workflow so that remote-operation failures can be analyzed through a consistent path instead of ad hoc guessing.

The capability must cover these scenarios:

- `git push`
- `git pull`
- `git fetch`
- `git ls-remote`

The primary user-facing goal is:

- when the main agent encounters a Git remote failure while executing a task, it should automatically trigger a diagnostics flow
- when auto-trigger does not happen or behaves incorrectly, the same diagnostics flow must also be available through a manual entrypoint

The capability is not limited to the current GitHub timeout case. It must diagnose common remote failure categories across configuration, authentication, network path, and repository policy.

## 2. Product Requirements

### 2.1 Automatic first, human fallback second

The system should collect and analyze everything it can from the local environment before asking the user to do anything.

User interaction is allowed only when the missing information cannot be observed from the CLI environment, such as:

- browser login state
- GitHub web permission state
- VPN or proxy client status
- operating system or corporate network policy controlled outside the shell
- user approval to change auth transport or credentials

### 2.2 Full diagnosis chain

The diagnostics flow must provide a complete path rather than a single-command check. It should produce a structured conclusion even when the failure is not automatically repairable.

### 2.3 General problem coverage

The capability is for generic Git remote failures, not just the current timeout symptom. The current incident is only one example that informed the design.

### 2.4 Main-agent-centered workflow

The expected execution shape is:

1. user asks the main agent to complete a task
2. the main agent runs a Git remote operation and encounters failure
3. the main agent creates a diagnostics sub-agent
4. the diagnostics sub-agent analyzes the failure and returns a structured solution
5. the main agent applies the proposed fix or performs the next recommended action
6. if unresolved, the main agent returns the new evidence to the diagnostics sub-agent
7. once resolved, the main agent reports the problem and the solution back to the user

## 3. Recommended Approach

This feature should use a dual-entrypoint, shared-core design.

### Approach chosen

Use one diagnostics core that is shared by:

- automatic trigger paths from the main agent
- a manual command or skill entrypoint

### Why this approach

This avoids splitting the logic into:

- one path for automatic diagnosis
- another path for manual rescue

Both entrypoints should call the same diagnostic rules, collect the same evidence, and produce the same output structure.

### Alternatives considered

#### A. Routing-only skill

Add only a skill and ask the main agent to remember to use it.

Rejected because it is too easy for the main agent to miss the trigger and because it does not provide a solid manual recovery path beyond freeform analysis.

#### B. Fully wrapped Git execution

Force all remote Git operations to go through wrapper commands that always intercept failure.

Rejected for now because it is more invasive than needed for the current plugin and does not match cases where the main agent runs a native Git command directly.

## 4. Architecture

Add four main assets to the repository.

### 4.1 Skill

`skills/liam-git-workflow-remote-diagnose/SKILL.md`

Responsibility:

- define when the capability applies
- define the diagnostics order
- define the output contract
- define when to continue automatically and when to ask the user

### 4.2 Manual command entrypoint

`claude/commands/liam-git-workflow-remote-diagnose.md`

Responsibility:

- provide a direct way to invoke remote diagnostics
- act as the fallback when auto-trigger misses a failure

### 4.3 Reference document

`references/remote-diagnostics.md`

Responsibility:

- document failure categories
- map signals to likely causes
- describe standard repair actions
- define escalation and human-interaction boundaries

### 4.4 Diagnostic script

`scripts/diagnose_git_remote.ps1`

Responsibility:

- collect local Git state
- collect remote and branch configuration
- collect proxy and credential-helper configuration
- perform minimal connectivity probes
- emit structured machine-readable output for the agent

## 5. Integration Points

The new capability must be wired into the existing framework instead of living as an isolated command.

### 5.1 Existing workflow entrypoint

Update:

- `skills/liam-git-workflow/SKILL.md`

Add routing rules so that:

- user-described remote failures are routed directly to the diagnostics capability
- remote-operation failures encountered during execution are escalated to the diagnostics capability

### 5.2 Existing command and scenario docs

Update the relevant command docs and scenarios so the new capability becomes part of the expected workflow, especially around sync and remote-access failures.

At minimum this should affect:

- `references/scenarios.md`
- sync-oriented command docs
- any docs that currently describe Git failure handling too generically

## 6. Trigger Model

The system should support both automatic and manual trigger paths.

### 6.1 Automatic trigger

The main agent should trigger diagnostics when a remote Git command fails with non-zero exit status and the command belongs to one of these families:

- `push`
- `pull`
- `fetch`
- `ls-remote`

The main agent should also inspect stderr for known failure patterns, such as:

- host resolution errors
- connection timeout or refusal
- TLS or SSL failures
- proxy failures
- authentication failures
- repository not found
- permission denied
- protected branch or policy rejection

### 6.2 Manual trigger

A manual entrypoint must remain available when:

- the main agent does not auto-trigger
- the routing is buggy
- the user wants to proactively diagnose a remote problem

Manual invocation should be possible through the workflow command system and by direct skill routing.

## 7. Diagnostics Flow

The diagnosis sequence must be stable and ordered. The order matters because it reduces false conclusions.

### 7.1 Local repository state

Check for local states that can invalidate the remote operation before network analysis begins:

- current branch
- detached HEAD
- merge or rebase in progress
- unresolved conflicts
- upstream presence
- working tree status when relevant

Purpose:

- prevent remote diagnosis when the real blocker is local state

### 7.2 Remote target validation

Check:

- configured remotes
- remote URLs
- branch upstream mapping
- remote naming assumptions
- basic plausibility of owner or repository target

Purpose:

- catch wrong remote target, missing upstream, and malformed repository references early

### 7.3 Authentication and authorization

Check:

- transport type in use: HTTPS or SSH
- credential helper configuration
- recognizable auth error signatures
- repository or branch access errors when visible from CLI output

Purpose:

- separate identity and permission issues from transport or network issues

### 7.4 Network path

Check:

- Git proxy configuration
- shell environment proxy variables
- DNS resolution
- TCP 443 reachability for HTTPS paths
- minimal HTTPS access probe
- `git ls-remote` behavior as a narrow remote-access test

Purpose:

- identify command-line network path problems such as proxy mismatch, DNS failure, timeout, TLS issues, or corporate filtering

### 7.5 Repository policy and server-side rules

Check for:

- protected branch rejection
- direct-push restrictions
- repository rename or removal
- organization policy messages

Purpose:

- avoid misclassifying server-side policy as client-side network failure

## 8. Output Contract

The diagnostics capability must return a structured result rather than freeform commentary.

Required fields:

- problem category
- evidence
- likely cause
- confidence
- actions already taken
- recommended next action
- whether human interaction is required
- if human interaction is required, exactly what the user must do and what result to return

This output is intended for the main agent to consume and act on, not only for user display.

## 9. Main Agent and Sub-Agent Collaboration

This design assumes a loop between execution and diagnosis.

### 9.1 Initial failure handoff

When a remote Git command fails, the main agent should pass this context to the diagnostics sub-agent:

- command attempted
- working directory
- exit code
- stderr or summarized failure output
- repository context when known
- diagnostic script output when available

### 9.2 Diagnostic result

The sub-agent should return:

- classification
- confidence
- repair proposal
- whether the main agent can apply it directly
- whether user interaction is required

### 9.3 Retry loop

The main agent should:

1. apply the proposed fix when safe and local
2. retry the original Git operation
3. if still failing, send the new result back into the diagnostics loop

### 9.4 User-facing closure

Once the issue is resolved, the main agent should summarize:

- what failed
- what category of problem it was
- what evidence supported the diagnosis
- what action fixed it

## 10. Human Interaction Rules

The diagnostics flow should ask the user only when that step depends on information outside command-line observability.

Examples:

- browser session or repository page access
- GitHub organization authorization pages
- VPN state
- proxy client state
- user approval to rotate or replace credentials
- system certificate or corporate device policy controlled outside the repository

When asking the user for help, the prompt must include:

1. why the step cannot be verified automatically
2. exactly what the user should check or do
3. exactly what the user should report back

## 11. Non-Goals

This design does not attempt to:

- solve every possible Git failure unrelated to remote access
- replace all native Git commands with wrappers
- guarantee fully automatic repair for credential issuance or corporate network policy problems

## 12. Implementation Boundaries

The first implementation should focus on:

- the shared diagnostics core
- automatic trigger conventions for main-agent execution
- a manual workflow command
- a structured diagnostic script
- documentation and routing updates

It should not expand into unrelated workflow refactoring.

## 13. Acceptance Criteria

The design is successful when:

- the project exposes a dedicated remote-diagnostics skill and manual command
- the main workflow knows to route remote failures into that capability
- the diagnostics path covers local state, remote config, auth, network, and policy in order
- the output is structured enough for a main agent to act on directly
- human interaction is minimized and standardized

## 14. Planned File Changes

New files:

- `skills/liam-git-workflow-remote-diagnose/SKILL.md`
- `claude/commands/liam-git-workflow-remote-diagnose.md`
- `references/remote-diagnostics.md`
- `scripts/diagnose_git_remote.ps1`

Files expected to be updated:

- `skills/liam-git-workflow/SKILL.md`
- `references/scenarios.md`
- relevant sync or remote-related command docs
