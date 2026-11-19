<!-- markdownlint-disable -->

# Hardening Report: Homebrew--actions--pre-build/2026.11.14.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Homebrew--actions--pre-build/2026.11.14.1** was hardened automatically. 1 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'Set up bottles directory' writes to $GITHUB_OUTPUT a value built from untrusted step outputs (MACOS_VERSION from steps.setup-cache.outputs.macos_version and ARCH from steps.setup-cache.outputs.arch, passed in through env). Nothing strips newlines before the write: `echo "bottle_specifier=$bottle_specifier" >> "$GITHUB_OUTPUT"`. Fix: run `printf '%s' "$bottle_specifier" | tr -d '\n\r'` on the value before writing it.

Locations:

- `action.yml:85`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

In the 'Set up bottles directory' step, bottle_specifier is now passed through printf '%s' | tr -d '\n\r' before it is written to $GITHUB_OUTPUT. The step runs under bash -euo pipefail. Separately, the line 'uses: $/setup-homebrew' looks malformed; it was already like that before this change, which did not touch it, and it should be checked.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In the 'Set up RubyGems cache' step of action.yml, the script used to write cache_key_prefix straight to $GITHUB_OUTPUT. It now strips newlines first with printf '%s' "$cache_key_prefix" | tr -d '\n\r'. The step runs with -euo pipefail and both commands always succeed, so behavior doesn't change. I didn't edit anything else, but the 'uses: $/setup-homebrew' reference looks malformed and might need a separate look.

