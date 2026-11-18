<!-- markdownlint-disable -->

# Hardening Report: Homebrew--actions--setup-ruby/2026.10.19.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Homebrew--actions--setup-ruby/2026.10.19.1** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

The 'Configure Bundler cache' step writes values taken from step outputs to $GITHUB_OUTPUT without first stripping newlines with `printf '%s' ... | tr -d '\n\r'`. The values are RUBY_VERSION (from steps.setup.outputs.ruby-version) and PORTABLE_RUBY (from steps.setup.outputs.portable-ruby), plus the inherited RUNNER_OS and RUNNER_ARCH env vars. They are joined into cache_prefix and written raw: `echo "cache-key=${cache_prefix}-${source_hash}" >> "${GITHUB_OUTPUT}"` and `echo "restore-key=${cache_prefix}-" >> "${GITHUB_OUTPUT}"`. bundle_path comes from `pwd` under the working directory set by the inputs.working-directory input, and is also written raw. Fix: clean each value with `safe=$(printf '%s' "$VAR" | tr -d '\n\r')` right before writing it.

Locations:

- `action.yml:112`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

In the 'Configure Bundler cache' step, bundle_path, cache_prefix and source_hash now go through printf '%s' | tr -d '\n\r' right before they are written to $GITHUB_OUTPUT. cache_prefix is built from RUNNER_OS, RUNNER_ARCH, RUBY_VERSION, PORTABLE_RUBY and the Ruby prefix hash. The step runs with bash -euo pipefail, so a failing command still stops it. Each value is assigned on its own line before it is cleaned, so no exit status gets hidden. Nothing else changed in behaviour. Not checked or changed: the 'Set up Homebrew' step reads 'uses: $/setup-homebrew', which isn't a valid action reference. The step only runs when setup-homebrew is 'true', so that path may fail.

