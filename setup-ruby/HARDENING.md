<!-- markdownlint-disable -->

# Hardening Report: Homebrew--actions--setup-ruby/2026.11.09.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Homebrew--actions--setup-ruby/2026.11.09.1** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'Configure Bundler cache' step builds cache_prefix from values the workflow controls and writes it to $GITHUB_OUTPUT without running printf '%s' ... | tr -d '\n\r' first. The values are RUBY_VERSION and PORTABLE_RUBY (both from steps.setup.outputs.*) and the inherited RUNNER_OS and RUNNER_ARCH. The writes are: echo "cache-key=${cache_prefix}-${source_hash}" >> "${GITHUB_OUTPUT}" and echo "restore-key=${cache_prefix}-" >> "${GITHUB_OUTPUT}". A newline in any of these values would add extra output entries.

Locations:

- `action.yml:138`
- `action.yml:141`
- `action.yml:142`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

In the 'Configure Bundler cache' step, cache_prefix, bundle_path and source_hash now go through printf '%s' | tr -d '\n\r' before they are written to $GITHUB_OUTPUT. These are plain variable assignments, so no command's exit status is hidden. The output keys and values are the same as before. I haven't run the action or re-run the analysis to confirm the finding is gone. Separately, I noticed 'uses: $/setup-homebrew' is not a valid uses: reference as written, which looks like a preprocessing artifact. I left it as it was.

