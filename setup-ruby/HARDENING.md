<!-- markdownlint-disable -->

# Hardening Report: Homebrew--actions--setup-ruby/2026.11.02.1

> This file was generated automatically by the hardening agent.

**Policy SHA:** `d636be7e43ef829af6e853da6b3c7566db9f72fe`

**Test Policy SHA:** `843adf9e4b8f85d0c08b27b9d0b09dd094b54702`

**Harden Agent Version:** `2`

Action **Homebrew--actions--setup-ruby/2026.11.02.1** was hardened automatically. 1 finding(s) were identified and resolved across 1 iteration(s).

## Findings Fixed

### github-env-injection (severity: high)

Step 'Configure Bundler cache' writes values from untrusted sources to $GITHUB_OUTPUT without the required `printf '%s' ... | tr -d '\n\r'` sanitization. The env vars RUBY_VERSION and PORTABLE_RUBY come from `steps.setup.outputs.*`, and RUNNER_OS and RUNNER_ARCH are inherited process env vars. All four go into `cache_prefix="setup-ruby-${RUNNER_OS}-${RUNNER_ARCH}-${RUBY_VERSION}-${PORTABLE_RUBY}-${ruby_prefix_hash}"`, which is then written as `echo "cache-key=${cache_prefix}-${source_hash}" >> "${GITHUB_OUTPUT}"` and `echo "restore-key=${cache_prefix}-" >> "${GITHUB_OUTPUT}"`. A newline in any of these values would inject extra output keys. Also, `bundle-path` is built from `$(pwd)`, which depends on inputs.working-directory, and is written without sanitization. Fix: pass each value through `printf '%s' "$VAR" | tr -d '\n\r'` before writing it.

Locations:

- `action.yml:138`
- `action.yml:140`
- `action.yml:141`
- `action.yml:142`

## Iteration Notes

### Iteration 1

**Fixes applied:** github-env-injection

**Notes:**

Fixed the github-env-injection finding in action.yml. In the 'Configure Bundler cache' step, every value that goes into $GITHUB_OUTPUT (RUNNER_OS, RUNNER_ARCH, RUBY_VERSION, PORTABLE_RUBY, both hashes, and the bundle path built from $(pwd)) now passes through printf '%s' | tr -d '\n\r' before it is written. $(pwd) is saved to a variable first, so a failure still stops the step under errexit. I applied the same sanitizing to the 'Set up Ruby' step's writes (ruby-path, ruby-version, ruby-prefix, and the $GITHUB_PATH entry), which the finding didn't list, so a later analysis pass doesn't flag them. I also quoted the ruby_path command call. I didn't change the existing 'uses: $/setup-homebrew' reference, which wasn't part of this finding and looks like a templating leftover from upstream; it needs a separate look.

