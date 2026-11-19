<!-- markdownlint-disable -->

# Hardening Report: Homebrew--actions--pre-build/2026.10.26.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Homebrew--actions--pre-build/2026.10.26.1** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'Set up bottles directory' builds bottle_specifier from MACOS_VERSION and ARCH. Both come from env vars set to ${{ steps.setup-cache.outputs.* }}. The step writes it with `echo "bottle_specifier=$bottle_specifier" >> "$GITHUB_OUTPUT"` and never runs the required `printf '%s' ... | tr -d '\n\r'` step first.

Locations:

- `action.yml:90`

### github-env-injection (severity: high)

Step 'Set up RubyGems cache' sets cache_key_prefix from the inherited process env var ${RUNNER_OS}. The run script reads this variable but does not set it. The step writes it with `echo "cache_key_prefix=${cache_key_prefix}" >> "${GITHUB_OUTPUT}"` and never runs the required `printf '%s' ... | tr -d '\n\r'` step first.

Locations:

- `action.yml:51`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

Both findings are fixed in action.yml. In 'Set up RubyGems cache', cache_key_prefix, macos_version and arch now have newlines and carriage returns stripped with printf '%s' | tr -d '\n\r' before they are written to GITHUB_OUTPUT. In 'Set up bottles directory', bottle_specifier gets the same treatment before it is written. Each command whose output is captured is a pipeline, and the step shell runs with -euo pipefail, so a failure still stops the step. Not tested.

Separate problem, not changed: the 'Set up Homebrew' step has 'uses: $/setup-homebrew', which is not a valid action reference. The step will probably fail at runtime and should be checked.

