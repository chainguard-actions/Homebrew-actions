<!-- markdownlint-disable -->

# Hardening Report: Homebrew--actions--setup-commit-signing/2026.10.26.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Homebrew--actions--setup-commit-signing/2026.10.26.1** was hardened automatically. 1 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### suspicious-run-content (severity: high)

eval-dynamic: the 'Enable SSH agent' step runs `eval $(ssh-agent)`, which matches the pattern eval\s+[`$]. The output being evaluated comes from the local ssh-agent binary, so this is probably the standard way to start ssh-agent and not malicious. It still matches the check pattern, and it runs command output through the shell. A safer option: start the agent with a known socket, e.g. `ssh-agent -a "$RUNNER_TEMP/ssh-agent.sock"`, then set SSH_AUTH_SOCK yourself instead of using eval.

Locations:

- `action.yml:25`

## Iteration Notes

### Iteration 1

**Fixes applied:** suspicious-run-content

**Notes:**

Removed the `eval $(ssh-agent)` call from the 'Enable SSH agent' step. The step now starts the agent with `ssh-agent -s -a` on a socket path it chooses under $RUNNER_TEMP, and sets SSH_AUTH_SOCK itself. It reads SSH_AGENT_PID from the agent's output with sed, and if no PID turns up it prints an error and exits instead of carrying on. Both values are still written to GITHUB_ENV as before. I haven't run the changed step.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In the 'Enable SSH agent' step, SSH_AUTH_SOCK is now passed through printf '%s' | tr -d '\n\r' before it is written to $GITHUB_ENV, and the $GITHUB_ENV path is quoted. SSH_AGENT_PID is written as before, because sed already reduces it to digits.

