<!-- markdownlint-disable -->

# Hardening Report: Homebrew--actions--setup-commit-signing/2026.11.02.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Homebrew--actions--setup-commit-signing/2026.11.02.1** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### suspicious-run-content (severity: high)

eval-dynamic: the 'Enable SSH agent' step runs `eval $(ssh-agent)`, which matches the pattern `eval\s+[\x60$]`. The output of the command substitution is run as shell code. The source here is the system ssh-agent binary, but any eval of command output is flagged. A safer pattern is `ssh-agent -a "$SOCK"` with a fixed socket path, or parsing SSH_AUTH_SOCK and SSH_AGENT_PID out of the output without eval.

Locations:

- `action.yml:25`

## Iteration Notes

### Iteration 1

**Fixes applied:** suspicious-run-content

**Notes:**

I replaced `eval $(ssh-agent)` in the 'Enable SSH agent' step. The step now runs `ssh-agent -s`, saves the output and reads SSH_AUTH_SOCK and SSH_AGENT_PID out of it with sed, so nothing from the output is run as shell code. If either value can't be parsed, the step fails with an error instead of carrying on with empty values. It then exports both values, prints the agent pid as before, and writes them to GITHUB_ENV the same way as before. I haven't run the changed step.

