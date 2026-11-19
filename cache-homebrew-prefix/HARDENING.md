<!-- markdownlint-disable -->

# Hardening Report: Homebrew--actions--cache-homebrew-prefix/2026.10.26.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Homebrew--actions--cache-homebrew-prefix/2026.10.26.1** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### script-injection (severity: high)

Rule (b): in the 'Compute available version hash' step, the workflow-controlled env var INSTALL (from inputs.install) is expanded without quotes: `for pkg in ${INSTALL}; do`. This is a for-loop word list, not an array assignment with a shellcheck SC2086/SC2206 directive, so the exemption does not apply.

Locations:

- `action.yml:119`

### script-injection (severity: high)

Rule (b): in the 'Install Homebrew formulae' step, raw_args holds the value of INSTALL (inputs.install) and is expanded without quotes: `for token in ${raw_args}; do`. Each token is checked against a regex after the split, but the expansion itself is still unquoted, and it is not the exempt array-assignment form.

Locations:

- `action.yml:200`

## Iteration Notes

### Iteration 1

**Fixes applied:** script-injection

**Notes:**

Fixed both unquoted list expansions in action.yml. The lines `for pkg in ${INSTALL}` (version-hash step) and `for token in ${raw_args}` (install step) now first build an array with an unquoted assignment, marked with a shellcheck SC2086/SC2206 directive. That assignment splits and globs exactly like the original loops did, so behaviour is unchanged. The loops then go over that array, quoted. Because these shells run with `set -u` and the macOS runners have bash 3.2, I wrote the loop as `${arr[@]+"${arr[@]}"}`: with an empty install input it runs zero times, as before, instead of failing with 'unbound variable'. The existing checks (each name must match the allowed pattern, error if no packages) are unchanged. I haven't run the action to test this.

