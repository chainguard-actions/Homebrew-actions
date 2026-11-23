<!-- markdownlint-disable -->

# Hardening Report: Homebrew--actions--setup-commit-signing/2026.11.23.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Homebrew--actions--setup-commit-signing/2026.11.23.1** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### suspicious-run-content (severity: high)

eval-dynamic: the 'Enable SSH agent' step runs `eval $(ssh-agent)`, which matches the pattern `eval\s+[\x60$]`. This is the standard way to start ssh-agent, and the evaluated output comes from a local binary, not from workflow input. It is still reported because the check matches on the pattern. A safer version would parse the ssh-agent output explicitly, for example `ssh-agent -s` followed by extracting SSH_AUTH_SOCK and SSH_AGENT_PID, or start the agent with `ssh-agent -a "$SOCK"` and export a known socket path.

Locations:

- `action.yml:25`

## Iteration Notes

### Iteration 1

**Fixes applied:** suspicious-run-content

**Notes:**

In action.yml, I replaced `eval $(ssh-agent)` in the 'Enable SSH agent' step. The step now runs `ssh-agent -s`, saves its output, and pulls out SSH_AUTH_SOCK and SSH_AGENT_PID with sed. If either value is missing, the step fails with an error instead of carrying on with empty values. Both values are exported in the step and written to GITHUB_ENV as before, and I quoted the GITHUB_ENV path. Nothing has been run, so the parsing has not been tried against real ssh-agent output.

