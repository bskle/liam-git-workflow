---
name: gw-diagnose
description: Diagnose Git remote operation failures (push/pull/fetch/ls-remote) through a five-layer systematic check covering local state, remote config, authentication, network path, and repository policy. Returns a structured diagnosis for the main agent to act on. Use when a remote Git command fails with non-zero exit status, or when the user suspects a remote connectivity problem.
---

# Git Remote Diagnostics

## Load First

Read these files before executing any diagnosis:

- `../../references/remote-diagnostics.md`
- `../../references/policy.md`

## Trigger Conditions

### Automatic Trigger

This skill activates automatically when:

1. A Git remote command (`push`, `pull`, `fetch`, `ls-remote`) returns a non-zero exit status.
2. The stderr output of the failed command matches one of the following known failure patterns:
   - Host resolution errors (`Could not resolve host`, `Name or service not known`)
   - Connection timeout or refusal (`Connection timed out`, `Connection refused`)
   - TLS/SSL failures (`SSL certificate problem`, `unable to get local issuer certificate`, `schannel: next InitializeSecurityContext failed`)
   - Proxy failures (`Proxy CONNECT aborted`, `tunneling socket could not be established`, `Received HTTP code 407 from proxy`)
   - Authentication failures (`Authentication failed`, `fatal: Authentication failed`, `HTTP 401`, `HTTP 403`)
   - Repository not found (`repository not found`, `fatal: repository '...' not found`, `HTTP 404`)
   - Permission denied (`Permission denied`, `You don't have the correct access rights`)
   - Protected branch / policy rejection (`protected branch`, `You don't have permission`, `Updates were rejected`)

### Manual Trigger

The user can invoke this skill directly via:

- The `gw-diagnose` command
- Direct skill routing from the main workflow hub
- Proactive invocation when remote connectivity is suspected but not yet confirmed by a failure

## Diagnostics Order

Execute diagnostics in this fixed order. Each layer must be checked before proceeding to the next, even if a problem is found at an earlier layer.

### 第 1 层：Local Repository State

**Purpose:** Prevent remote diagnosis when the real blocker is a local state issue.

**Checks:**

- Current branch and detached HEAD detection
- In-progress merge or rebase (`git status`, check for `.git/MERGE_HEAD`, `.git/rebase-merge`, `.git/rebase-apply`)
- Unresolved conflicts (`git status --porcelain`, check for `UU` status)
- Upstream branch configuration (`git branch -vv`, check for missing upstream)
- Working tree status when relevant (uncommitted changes may block certain operations)

### 第 2 层：Remote Target Validation

**Purpose:** Catch wrong remote targets, missing upstreams, and malformed repository references early.

**Checks:**

- Configured remotes (`git remote -v`, verify remote names and URLs)
- Remote URL format validation (HTTPS: `https://<host>/<owner>/<repo>.git`, SSH: `git@<host>:<owner>/<repo>.git`)
- Branch upstream mapping (`git branch -vv`, confirm current branch tracks a valid remote branch)
- Owner/repository target plausibility (check for obvious typos or missing segments)

### 第 3 层：Authentication and Authorization

**Purpose:** Separate identity and permission issues from transport or network issues.

**Checks:**

- Transport type determination (HTTPS or SSH based on remote URL)
- Credential helper configuration (`git config --get credential.helper`, check for configured helpers)
- Recognizable auth error signatures (401 Unauthorized, 403 Forbidden, SSH permission denied)
- Repository or branch access errors visible from CLI output
- Distinguish authentication failure (bad/missing credentials) from authorization failure (credentials valid but insufficient permissions)

### 第 4 层：Network Path

**Purpose:** Identify command-line network path problems such as proxy mismatch, DNS failure, timeout, TLS issues, or corporate filtering.

**Checks:**

- Git proxy configuration (`git config --get http.proxy`, `git config --get https.proxy`)
- Shell environment proxy variables (`env | grep -i proxy`, check `HTTP_PROXY`, `HTTPS_PROXY`, `NO_PROXY`)
- DNS resolution (`nslookup <host>`, verify the Git remote host resolves)
- TCP 443 reachability for HTTPS paths (`Test-NetConnection <host> -Port 443` on Windows)
- Minimal HTTPS access probe (`curl -I https://<host>` or equivalent)
- `git ls-remote` behavior as a narrow remote-access test (bypasses full push/pull, tests auth + network together)

### 第 5 层：Repository Policy and Server-Side Rules

**Purpose:** Avoid misclassifying server-side policy as client-side network failure.

**Checks:**

- Protected branch rejection detection (error messages containing "protected branch", "required status check", "required review")
- Direct-push restrictions (force push denied, non-fast-forward rejection)
- Repository rename or removal indicators (HTTP 404 with "repository not found" on a previously working remote)
- Organization policy messages (IP allow list, required 2FA, organization access restrictions)

## Output Contract

The diagnosis must return a structured result with the following fields. This output is intended for the main agent to consume and act on.

| Field | Type | Description |
|-------|------|-------------|
| `problem_category` | `string` | Primary problem category, aligned with the failure classification in the reference knowledge base |
| `evidence` | `string[]` | Observed signals and CLI output excerpts collected during diagnosis |
| `likely_cause` | `string` | Most likely root cause based on signal-to-cause mapping |
| `confidence` | `enum: high \| medium \| low` | Confidence assessment based on the strength and consistency of collected evidence |
| `actions_taken` | `string[]` | Diagnostic steps already executed, in order |
| `recommended_next_action` | `string` | Specific, executable next step to resolve the issue (the main agent should be able to execute this directly) |
| `human_interaction_required` | `boolean` | Whether the recommended next action requires human interaction |
| `human_action_detail` | `string \| null` | If human interaction is required, exactly what the user must do and what result to report back; `null` if not required |

## Human Interaction Rules

Only ask the user for help when the required information cannot be observed from the CLI environment. The following information categories are outside CLI observability:

- Browser session state or repository page access status
- GitHub organization authorization pages
- VPN client state
- Proxy client GUI state
- User approval to rotate or replace credentials
- System certificate or corporate device policy controlled outside the repository

When `human_interaction_required` is `true`, the interaction prompt must include three components:

1. **Why this step cannot be automated:** Explain what information is needed and why it is not observable from the CLI.
2. **What the user should check or do:** Provide the exact operation or navigation steps the user should perform.
3. **What the user should report back:** Specify the exact information to return, so the diagnosis can continue with the new data.

The result must populate `human_action_detail` with the exact instructions for the user.

## Response Style

- State the detected problem category and confidence level in the first sentence
- List each diagnostic layer checked and its key findings, in the order they were executed (第 1 层 through 第 5 层)
- Provide the recommended next action as a specific, executable step that the main agent can apply directly
- Clearly state whether human interaction is required and, if so, provide the exact interaction prompt following the three-component format
- When multiple problems are found, classify the primary one and note secondary findings
- If no definitive cause is found, state the uncertainty, list what was checked, and recommend escalation
