<!-- markdownlint-disable -->

# Hardening Report: Homebrew--actions--cache-homebrew-prefix/2026.11.23.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Homebrew--actions--cache-homebrew-prefix/2026.11.23.1** was hardened automatically. 2 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b): in the 'Compute available version hash' step, the env var INSTALL (set from inputs.install) is expanded without quotes as a for-loop word list: `for pkg in ${INSTALL}; do`. The unquoted expansion splits on whitespace and expands glob characters taken from workflow-controlled input. This is a for-loop, not an array assignment with a shellcheck SC2086/SC2206 directive, so the exemption does not apply. Split the value safely before using it (for example, turn off globbing with set -f around the loop).

Locations:

- `action.yml:119`

### script-injection (severity: high)

Rule (b): in the 'Install Homebrew formulae' step, raw_args (copied from INSTALL, which is set from inputs.install) is expanded without quotes as a for-loop word list: `for token in ${raw_args}; do`. Glob characters in the input get expanded against the filesystem before each token is checked against the regex. This is a for-loop, not an array assignment with a shellcheck directive, so the exemption does not apply.

Locations:

- `action.yml:200`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Turned off globbing (set -f / set +f) around both for-loops in action.yml that split INSTALL ('Compute available version hash') and raw_args ('Install Homebrew formulae'). They still split on whitespace the same way, but glob characters in inputs.install no longer match files on disk. Valid package names can't contain glob characters (the install step's regex rejects them), so normal formula lists work exactly as before.

### Iteration 2

**Fixes applied:** script-injection

**Notes:**

I fixed both flagged loops in action.yml, in the 'Compute available version hash' and 'Install Homebrew formulae' steps. Each one now splits the list into an array with an unquoted array assignment inside `set -f`, marked with a `# shellcheck disable=SC2206` comment, then loops over the array quoted. Splitting is the same as upstream's: on whitespace, with no globbing. The `${arr[@]+...}` guard means an empty array doesn't trip `set -u` on older bash versions. The existing check that rejects option flags and invalid package names is unchanged.

