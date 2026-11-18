<!-- markdownlint-disable -->

# Hardening Report: Homebrew--actions--pre-build/2026.10.19.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Homebrew--actions--pre-build/2026.10.19.1** was hardened automatically. 2 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'Set up bottles directory' writes bottle_specifier to $GITHUB_OUTPUT built from MACOS_VERSION and ARCH, which come from steps.setup-cache.outputs.* (untrusted per check scope). The value is not passed through printf '%s' ... | tr -d '\n\r' first: echo "bottle_specifier=$bottle_specifier" >> "$GITHUB_OUTPUT"

Locations:

- `action.yml:85`

### github-env-injection (severity: high)

Step 'Set up RubyGems cache' writes cache_key_prefix to $GITHUB_OUTPUT. On non-macOS runners this value comes from the inherited process env var RUNNER_OS, which the script reads but does not set. The value is not passed through printf '%s' ... | tr -d '\n\r' first: echo "cache_key_prefix=${cache_key_prefix}" >> "${GITHUB_OUTPUT}"

Locations:

- `action.yml:50`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

In action.yml, the 'Set up RubyGems cache' step now strips \n and \r from cache_key_prefix, macos_version and arch (using printf '%s' ... | tr -d '\n\r') before writing them to $GITHUB_OUTPUT. The 'Set up bottles directory' step does the same to bottle_specifier before writing it. Each value is assigned on its own line, so the step's errexit and pipefail behaviour stays as it was. Separately, the existing 'uses: $/setup-homebrew' line looks malformed, but no finding covered it, so I left it unchanged; it should be checked.

