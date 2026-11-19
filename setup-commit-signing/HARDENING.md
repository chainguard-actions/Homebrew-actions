<!-- markdownlint-disable -->

# Hardening Report: Homebrew--actions--setup-commit-signing/2026.11.14.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Homebrew--actions--setup-commit-signing/2026.11.14.1** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### suspicious-run-content (severity: high)

eval-dynamic: the 'Enable SSH agent' step runs `eval $(ssh-agent)`, which matches the pattern `eval\s+[\x60$]`. This is the standard way to start ssh-agent and the command substitution runs a fixed binary, not user input. It is still reported because the check flags any eval of command substitution.

Locations:

- `action.yml:25`

## Iteration Notes

### Iteration 1

**Fixes applied:** suspicious-run-content

**Notes:**

Replaced `eval $(ssh-agent)` in the 'Enable SSH agent' step with parsing `ssh-agent -s` output via sed to extract SSH_AUTH_SOCK and SSH_AGENT_PID (fails if parsing fails), exporting them and writing to GITHUB_ENV as before (now quoted). Behavior is otherwise identical, including the 'Agent pid N' log line.

