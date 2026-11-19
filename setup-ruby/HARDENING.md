<!-- markdownlint-disable -->

# Hardening Report: Homebrew--actions--setup-ruby/2026.11.14.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Homebrew--actions--setup-ruby/2026.11.14.1** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'Configure Bundler cache' (action.yml) writes values from workflow-controlled sources to $GITHUB_OUTPUT without first running them through `printf '%s' ... | tr -d '\n\r'`. RUBY_VERSION and PORTABLE_RUBY come from `steps.setup.outputs.*` env vars. RUNNER_OS and RUNNER_ARCH are inherited process env vars that the script reads but doesn't set. All four are joined into cache_prefix (`cache_prefix="setup-ruby-${RUNNER_OS}-${RUNNER_ARCH}-${RUBY_VERSION}-${PORTABLE_RUBY}-${ruby_prefix_hash}"`) and then written as `echo "cache-key=${cache_prefix}-${source_hash}" >> "${GITHUB_OUTPUT}"` and `echo "restore-key=${cache_prefix}-" >> "${GITHUB_OUTPUT}"`. A newline in any of these values would let extra output lines be injected. Fix: strip newlines from cache_prefix (or from each part) with `printf '%s' ... | tr -d '\n\r'` before writing.

Locations:

- `action.yml:138`
- `action.yml:141`
- `action.yml:142`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

In the 'Configure Bundler cache' step of action.yml, cache_prefix (made from RUNNER_OS, RUNNER_ARCH, RUBY_VERSION, PORTABLE_RUBY and the prefix hash), source_hash and bundle_path now go through printf '%s' | tr -d '\n\r' before being written to GITHUB_OUTPUT. The command substitutions run on their own lines first, so errexit still stops the step if one fails. Nothing else changed. I left the unrelated 'uses: $/setup-homebrew' reference exactly as it was found, but it looks malformed and probably breaks setup-homebrew: true.

