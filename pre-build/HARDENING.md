<!-- markdownlint-disable -->

# Hardening Report: Homebrew--actions--pre-build/2026.11.09.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Homebrew--actions--pre-build/2026.11.09.1** was hardened automatically. 1 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'Set up bottles directory' step builds bottle_specifier from the MACOS_VERSION and ARCH env vars. Those vars come from ${{ steps.setup-cache.outputs.macos_version }} and ${{ steps.setup-cache.outputs.arch }}, which are untrusted step outputs under this check. The step then writes the value to $GITHUB_OUTPUT with `echo "bottle_specifier=$bottle_specifier" >> "$GITHUB_OUTPUT"` and never strips newlines first. A value containing a newline could add extra output lines. Fix: write `safe=$(printf '%s' "$bottle_specifier" | tr -d '\n\r')` before the write, then echo "$safe".

Locations:

- `action.yml:85`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

In the 'Set up bottles directory' step, bottle_specifier now has newlines stripped (printf '%s' | tr -d '\n\r') before it is written to $GITHUB_OUTPUT. The step's shell runs with pipefail, so the pipeline's exit status is still checked. Not changed, outside the scope of this finding: the 'Set up Homebrew' step has 'uses: $/setup-homebrew', which looks malformed. It is probably an expression that got substituted badly. Please check it separately.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In the 'Set up RubyGems cache' step, cache_key_prefix, macos_version and arch now go through printf '%s' | tr -d '\n\r' before being written to $GITHUB_OUTPUT. The values are still computed by plain assignments, so under errexit/pipefail a failing command still stops the step. Possible problem outside this finding, left unchanged: the 'Set up Homebrew' step reads 'uses: $/setup-homebrew', which looks like a mangled reference and should be checked.

