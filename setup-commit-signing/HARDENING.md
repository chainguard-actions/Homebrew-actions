<!-- markdownlint-disable -->

# Hardening Report: Homebrew--actions--setup-commit-signing/2026.11.09.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Homebrew--actions--setup-commit-signing/2026.11.09.1** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### suspicious-run-content (severity: high)

eval-dynamic: the 'Enable SSH agent' step runs `eval $(ssh-agent)`, which matches the pattern `eval\s+[\x60$]`. This is the usual way to start ssh-agent, and the command it evaluates is fixed rather than built from input, so the real risk is low. It still breaks the rule against eval with command substitution. Safer option: run `ssh-agent -s` and parse SSH_AUTH_SOCK and SSH_AGENT_PID from its output explicitly, or start the agent at a known socket with `ssh-agent -a "$SOCK"`.

Locations:

- `action.yml:25`

## Iteration Notes

### Iteration 1

**Fixes applied:** suspicious-run-content

**Notes:**

In action.yml, the 'Enable SSH agent' step no longer runs `eval $(ssh-agent)`. It now runs `ssh-agent -s` and reads SSH_AUTH_SOCK and SSH_AGENT_PID out of the output with sed. If either value can't be found, the step stops with a clear error. Otherwise both are exported and written to GITHUB_ENV the same way as before. I haven't run the changed step, so it isn't tested yet.

