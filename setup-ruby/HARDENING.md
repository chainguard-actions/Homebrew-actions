<!-- markdownlint-disable -->

# Hardening Report: Homebrew--actions--setup-ruby/2026.10.26.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Homebrew--actions--setup-ruby/2026.10.26.1** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'Configure Bundler cache' writes values taken from workflow-controlled sources to $GITHUB_OUTPUT without first running them through `printf '%s' ... | tr -d '\n\r'`. The sources are the env vars RUBY_VERSION and PORTABLE_RUBY, which come from steps.setup.outputs.*, and RUNNER_OS and RUNNER_ARCH, which are inherited process env vars. All of them are joined into cache_prefix, which is then written by: `echo "cache-key=${cache_prefix}-${source_hash}" >> "${GITHUB_OUTPUT}"` and `echo "restore-key=${cache_prefix}-" >> "${GITHUB_OUTPUT}"`. If any of these values contained a newline, it could add extra output lines. To fix this, strip newlines and carriage returns from cache_prefix before writing it.

Locations:

- `action.yml:146`
- `action.yml:149`
- `action.yml:150`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

In the 'Configure Bundler cache' step, cache_prefix (built from RUNNER_OS, RUNNER_ARCH, RUBY_VERSION and PORTABLE_RUBY) now goes through printf '%s' | tr -d '\n\r' before it is written to GITHUB_OUTPUT as cache-key and restore-key. bundle_path is cleaned the same way. Since the step runs with pipefail, any failure still stops it. Nothing else in the file was changed.

