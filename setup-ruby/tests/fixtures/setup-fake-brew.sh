#!/bin/bash
# Installs a fake `brew` (plus fake ruby/bundle created on demand) under
# /tmp/fakebrew so the action's logic can be exercised without Homebrew.
# Usage: setup-fake-brew.sh [installed|missing]
#   installed - the Ruby formula is already "installed" (brew install not needed)
#   missing   - the Ruby formula is absent; `brew install ruby` creates it
set -euo pipefail

MODE="${1:-installed}"
ROOT=/tmp/fakebrew

rm -rf "$ROOT"
mkdir -p "$ROOT/bin" "$ROOT/repo"
: > "$ROOT/calls.log"

cat > "$ROOT/make-ruby.sh" <<'EOF'
#!/bin/bash
set -euo pipefail
prefix="$1"
mkdir -p "$prefix/bin"
cat > "$prefix/bin/ruby" <<'RUBY'
#!/bin/bash
echo "ruby $*" >> /tmp/fakebrew/calls.log
if [ "${1:-}" = "-e" ]; then
  printf '3.3.5'
  exit 0
fi
echo "ruby 3.3.5 (fake)"
RUBY
cat > "$prefix/bin/bundle" <<'BUNDLE'
#!/bin/bash
echo "bundle $*" >> /tmp/fakebrew/calls.log
case "${1:-}" in
  check)
    if [ -f /tmp/fakebrew/bundle-check-ok ]; then exit 0; fi
    exit 1
    ;;
esac
exit 0
BUNDLE
chmod +x "$prefix/bin/ruby" "$prefix/bin/bundle"
EOF
chmod +x "$ROOT/make-ruby.sh"

cat > "$ROOT/bin/brew" <<'EOF'
#!/bin/bash
echo "brew $*" >> /tmp/fakebrew/calls.log
case "$*" in
  "--prefix ruby") echo /tmp/fakebrew/ruby ;;
  "--repository") echo /tmp/fakebrew/repo ;;
  "install ruby") /tmp/fakebrew/make-ruby.sh /tmp/fakebrew/ruby ;;
  "vendor-install ruby") /tmp/fakebrew/make-ruby.sh /tmp/fakebrew/repo/Library/Homebrew/vendor/portable-ruby/current ;;
  *) echo "fake brew: unsupported args: $*" >&2; exit 1 ;;
esac
EOF
chmod +x "$ROOT/bin/brew"

if [ "$MODE" = "installed" ]; then
  "$ROOT/make-ruby.sh" "$ROOT/ruby"
fi

if [ -n "${GITHUB_PATH:-}" ]; then
  echo "$ROOT/bin" >> "$GITHUB_PATH"
fi

# The action's first step calls "$GITHUB_ACTION_PATH/../deprecate-master.sh",
# a sibling script from the Homebrew/actions monorepo. Provide a no-op stand-in
# if it is not present next to the action.
for base in "${GITHUB_WORKSPACE:-$PWD}"; do
  stub="$base/../deprecate-master.sh"
  if [ ! -e "$stub" ]; then
    { printf '#!/bin/sh\nexit 0\n' > "$stub" && chmod +x "$stub"; } 2>/dev/null || \
      echo "warning: could not create $stub"
  fi
done
