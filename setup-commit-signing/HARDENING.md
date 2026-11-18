<!-- markdownlint-disable -->

# Hardening Report: Homebrew--actions--setup-commit-signing/2026.10.19.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Homebrew--actions--setup-commit-signing/2026.10.19.1** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### suspicious-run-content (severity: high)

eval-dynamic: the 'Enable SSH agent' step runs `eval $(ssh-agent)`, which matches the pattern eval\s+[\x60$]. The output of ssh-agent is executed as shell code. This is the usual way to start ssh-agent, but it still matches the eval-with-command-substitution pattern. Safer option: run `ssh-agent -s`, then parse SSH_AUTH_SOCK and SSH_AGENT_PID from its output explicitly instead of eval-ing it.

Locations:

- `action.yml:25`

## Iteration Notes

### Iteration 1

**Fixes applied:** suspicious-run-content

**Notes:**

In action.yml, I replaced `eval $(ssh-agent)` with `ssh-agent -s`. The step now reads SSH_AUTH_SOCK and SSH_AGENT_PID out of that output with sed, removes any newlines, and stops with an error if either value is missing. It then exports both, prints the agent pid like ssh-agent's own output did, and writes them to GITHUB_ENV the same way as before. I haven't run the action to test this.

