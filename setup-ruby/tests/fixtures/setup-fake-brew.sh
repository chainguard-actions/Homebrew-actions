#!/bin/bash
# Creates a fake `brew` under /tmp/fake-brew and prints its bin dir.
# Usage: setup-fake-brew.sh [preinstall-formula-ruby: true|false]
set -euo pipefail
ROOT=/tmp/fake-brew
PREINSTALL="${1:-false}"
rm -rf "$ROOT"
mkdir -p "$ROOT/bin" "$ROOT/repo"
: > "$ROOT/brew.log"
: > "$ROOT/bundle.log"

cat > "$ROOT/make-ruby.sh" <<'EOF'
#!/bin/bash
set -euo pipefail
prefix="$1"
mkdir -p "$prefix/bin"
cat > "$prefix/bin/ruby" <<'RUBY'
#!/bin/sh
printf '%s' "3.4.7"
RUBY
cat > "$prefix/bin/bundle" <<'BUNDLE'
#!/bin/sh
echo "bundle $* (pwd=$(pwd))" >> /tmp/fake-brew/bundle.log
if [ "$1" = "check" ]; then
  exit 1
fi
exit 0
BUNDLE
chmod +x "$prefix/bin/ruby" "$prefix/bin/bundle"
EOF
chmod +x "$ROOT/make-ruby.sh"

cat > "$ROOT/bin/brew" <<'EOF'
#!/bin/bash
ROOT=/tmp/fake-brew
echo "brew $*" >> "$ROOT/brew.log"
case "$1" in
  --prefix) echo "$ROOT/opt/ruby" ;;
  --repository) echo "$ROOT/repo" ;;
  install) "$ROOT/make-ruby.sh" "$ROOT/opt/ruby" ;;
  vendor-install) "$ROOT/make-ruby.sh" "$ROOT/repo/Library/Homebrew/vendor/portable-ruby/current" ;;
  *) ;;
esac
exit 0
EOF
chmod +x "$ROOT/bin/brew"

if [ "$PREINSTALL" = "true" ]; then
  "$ROOT/make-ruby.sh" "$ROOT/opt/ruby"
fi
