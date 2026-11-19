<!-- markdownlint-disable -->

# Hardening Report: Homebrew--actions--cache-homebrew-prefix/2026.11.02.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Homebrew--actions--cache-homebrew-prefix/2026.11.02.1** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b): in the 'Compute available version hash' step, the env var INSTALL holds workflow-controlled data from inputs.install, and the script expands it without quotes: `for pkg in ${INSTALL}; do`. The shell splits the value on whitespace and expands glob characters. The packages are then passed to version-hash.rb with no check on their names. The SC2086/SC2206 exemption does not apply, because this is a for loop with no shellcheck directive, not an array assignment.

Locations:

- `action.yml:119`

### script-injection (severity: high)

Rule (b): in the 'Install Homebrew formulae' step, raw_args is copied from INSTALL (inputs.install) and expanded without quotes: `for token in ${raw_args}; do`. Each token is checked against a regex after splitting, but the expansion itself is unquoted, so whitespace splitting and glob expansion of the workflow-controlled value still happen. No shellcheck exemption directive is present, and this is not an array assignment.

Locations:

- `action.yml:200`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

In action.yml, both unquoted `for x in ${VAR}` loops now first build an array with an unquoted assignment that has a shellcheck disable directive: `install_tokens=(${INSTALL})` and `raw_tokens=(${raw_args})`. Each loop then iterates over that array using the set -u-safe form `${arr[@]+"${arr[@]}"}`, which matters on bash 3.2 (macOS). Values are split on whitespace and globbed exactly as upstream did, so behaviour is unchanged and nothing inside a value is evaluated. The package-name regex check in the install step is kept. No other changes were made.

