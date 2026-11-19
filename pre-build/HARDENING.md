<!-- markdownlint-disable -->

# Hardening Report: Homebrew--actions--pre-build/2026.11.02.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Homebrew--actions--pre-build/2026.11.02.1** was hardened automatically. 1 finding(s) were identified and resolved across 2 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'Set up bottles directory' (id: setup-bottles) writes `bottle_specifier` to $GITHUB_OUTPUT. The value is built from MACOS_VERSION and ARCH, which come from `${{ steps.setup-cache.outputs.macos_version }}` and `${{ steps.setup-cache.outputs.arch }}`. Nothing strips newlines from it first: `echo "bottle_specifier=$bottle_specifier" >> "$GITHUB_OUTPUT"`. The check counts steps.*.outputs.* as untrusted, so the value must go through `printf '%s' ... | tr -d '\n\r'` before the write.

Locations:

- `action.yml:90`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

In action.yml, the 'Set up bottles directory' step (id: setup-bottles) now runs bottle_specifier through printf '%s' | tr -d '\n\r' before writing it to $GITHUB_OUTPUT. This step's shell already uses -euo pipefail, so a failure anywhere in that pipeline still stops the step. I didn't change anything else. One unrelated thing looks wrong: the 'Set up Homebrew' step says 'uses: $/setup-homebrew', which doesn't look like a valid reference. It wasn't part of this finding, so I left it alone, but it's worth checking before release.

### Iteration 2

**Fixes applied:** github-env-injection

**Notes:**

In the 'Set up RubyGems cache' step, cache_key_prefix, macos_version and arch are now written to $GITHUB_OUTPUT through printf '%s' | tr -d '\n\r'. Before this, RUNNER_OS went into the output unchecked. Each value is captured on its own line and cleaned afterwards, so a failing command still stops the step under -euo pipefail. Nothing else changed in the step. Separately, I left 'uses: $/setup-homebrew' as I found it because it wasn't part of this finding. It looks malformed, though, so someone should check it.

