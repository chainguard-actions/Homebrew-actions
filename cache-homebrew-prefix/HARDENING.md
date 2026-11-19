<!-- markdownlint-disable -->

# Hardening Report: Homebrew--actions--cache-homebrew-prefix/2026.11.14.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Homebrew--actions--cache-homebrew-prefix/2026.11.14.1** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b) violation in the 'Compute available version hash' step. The workflow-controlled env var INSTALL (set from inputs.install) is expanded without quotes in a for loop: `for pkg in ${INSTALL}; do`. This is a for-loop, not a NAME=($VAR) array assignment carrying a shellcheck SC2086/SC2206 directive, so the exemption does not apply. Glob characters in the input get expanded against the filesystem. The step should split the list safely (e.g. into an array assignment with the shellcheck directive) and use "${pkg}" afterwards.

Locations:

- `action.yml:118`

### script-injection (severity: high)

Rule (b) violation in the 'Install Homebrew formulae' step. raw_args is copied from the workflow-controlled env var INSTALL (inputs.install) and expanded without quotes: `for token in ${raw_args}; do`. Each token is checked against a regex afterwards, but glob expansion happens before that check, during word splitting. This is not the exempted array-assignment form with a shellcheck directive.

Locations:

- `action.yml:194`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

I fixed both script-injection findings in action.yml (the 'Compute available version hash' and 'Install Homebrew formulae' steps). Each unquoted `for x in ${VAR}` loop now first copies the value into an array with an unquoted assignment and a `# shellcheck disable=SC2086,SC2206` comment (`install_list=(${INSTALL})` and `raw_list=(${raw_args})`). The loops then go over the array with a quoted expansion. The value is split and globbed exactly as upstream did. I used the `${arr[@]+"${arr[@]}"}` form for the loops so an empty install input still works with `set -u` under bash 3.2 on macOS. The later 'no packages' and package-name checks are unchanged. Nothing was run or tested.

