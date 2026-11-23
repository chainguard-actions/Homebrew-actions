<!-- markdownlint-disable -->

# Hardening Report: Homebrew--actions--pre-build/2026.11.23.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Homebrew--actions--pre-build/2026.11.23.1** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'Set up bottles directory' builds bottle_specifier from MACOS_VERSION and ARCH (env vars set from ${{ steps.setup-cache.outputs.* }}) and writes it to $GITHUB_OUTPUT with `echo "bottle_specifier=$bottle_specifier" >> "$GITHUB_OUTPUT"`. The value is not sanitized with `printf '%s' ... | tr -d '\n\r'` first. The output then flows into the download-artifact pattern.

Locations:

- `action.yml:85`

### github-env-injection (severity: high)

Step 'Set up RubyGems cache' sets cache_key_prefix="${RUNNER_OS}", a process env var inherited by the composite action and not set in this script, on non-macOS runners. It then writes it to $GITHUB_OUTPUT with `echo "cache_key_prefix=${cache_key_prefix}" >> "${GITHUB_OUTPUT}"`. The value is not sanitized with `printf '%s' ... | tr -d '\n\r'` first.

Locations:

- `action.yml:50`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

In action.yml, both $GITHUB_OUTPUT writes now strip newlines first. Each value goes through printf '%s' ... | tr -d '\n\r' before it is written. In 'Set up RubyGems cache' this covers cache_key_prefix, and also macos_version and arch. In 'Set up bottles directory' it covers bottle_specifier. Each value is captured in its own variable assignment with no wrapper around a command substitution, so errexit still stops the step if a command fails. These values are single-line, so the change does not alter normal output. Nothing was run or tested. Separately, the line 'uses: $/setup-homebrew' is malformed as written; I left it alone because it is outside these findings, but it may be a placeholder that needs checking.

