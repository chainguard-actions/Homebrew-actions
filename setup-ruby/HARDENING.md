<!-- markdownlint-disable -->

# Hardening Report: Homebrew--actions--setup-ruby/2026.11.23.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Homebrew--actions--setup-ruby/2026.11.23.1** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'Configure Bundler cache' writes workflow-controlled values to $GITHUB_OUTPUT without the required sanitization (printf '%s' ... | tr -d '\n\r'). These values come from the earlier step's outputs (steps.setup.outputs.ruby-version and steps.setup.outputs.portable-ruby, passed in as env vars) and from inherited runner env vars ($RUNNER_OS, $RUNNER_ARCH). They are joined into cache_prefix and then written with: echo "cache-key=${cache_prefix}-${source_hash}" >> "${GITHUB_OUTPUT}" and echo "restore-key=${cache_prefix}-" >> "${GITHUB_OUTPUT}". bundle_path (from $(pwd), which depends on the working-directory input) is written the same way: echo "bundle-path=${bundle_path}" >> "${GITHUB_OUTPUT}". If any of these values contains a newline, it can inject extra outputs. Fix: strip CR and LF before each write, e.g. safe=$(printf '%s' "$cache_prefix" | tr -d '\n\r').

Locations:

- `action.yml:140`
- `action.yml:141`
- `action.yml:142`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

In the 'Configure Bundler cache' step of action.yml, bundle_path, cache_prefix and source_hash now have CR and LF removed with printf '%s' | tr -d '\n\r' before they go to $GITHUB_OUTPUT. The values come only from variables, so a failing command still stops the step (bash -euo pipefail). The written values are unchanged unless one contains a newline. I left one thing alone that I noticed: the 'Set up Homebrew' step has an odd 'uses: $/setup-homebrew' reference. It looks like a mangled local action path. It wasn't part of this finding and I didn't know the intended value, but it needs checking because that step probably won't resolve.

