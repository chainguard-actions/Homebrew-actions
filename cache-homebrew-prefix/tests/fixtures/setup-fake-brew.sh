#!/usr/bin/env bash
# Sets up a fake `brew` on PATH so the composite action can be exercised under act
# (real Homebrew refuses to install as root inside the act container).
set -euo pipefail

FB=/tmp/fakebrew
rm -rf "$FB"
mkdir -p "$FB/bin" "$FB/prefix" "$FB/repo/Library/Homebrew/vendor/portable-ruby/current/bin" "$FB/cache/api"
echo "fake prefix content" > "$FB/prefix/README"
: > "$FB/calls.log"

# Real Ruby is needed to run version-hash.rb.
if ! command -v ruby >/dev/null 2>&1; then
  SUDO=""
  if [ "$(id -u)" != "0" ]; then SUDO="sudo"; fi
  $SUDO apt-get update -qq
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq --no-install-recommends ruby >/dev/null
fi
ln -sf "$(command -v ruby)" "$FB/repo/Library/Homebrew/vendor/portable-ruby/current/bin/ruby"

cp "$GITHUB_WORKSPACE/tests/fixtures/formula.jws.json" "$FB/cache/api/formula.jws.json"

cat > "$FB/bin/brew" <<'EOF'
#!/usr/bin/env bash
FB=/tmp/fakebrew
echo "brew $*" >> "$FB/calls.log"
case "${1:-}" in
  --prefix) echo "$FB/prefix" ;;
  --repository) echo "$FB/repo" ;;
  --cache) echo "$FB/cache" ;;
  list)
    if [ -f "$FB/installed" ]; then cat "$FB/installed"; fi
    ;;
  install|upgrade) exit 0 ;;
  test-bot) rm -f "$FB/installed" ;;
  bundle)
    case "${2:-}" in
      list)
        file="${@: -1}"
        grep -E '^brew "' "$file" | sed -E 's/^brew "([^"]+)".*/\1/'
        ;;
      check) exit 1 ;;
      *) exit 0 ;;
    esac
    ;;
  *) exit 0 ;;
esac
EOF
chmod +x "$FB/bin/brew"
echo "$FB/bin" >> "$GITHUB_PATH"

# The action's first step calls "$GITHUB_ACTION_PATH/../deprecate-master.sh".
# Provide a no-op stub if the harness layout doesn't ship one.
for candidate in "$GITHUB_WORKSPACE/../deprecate-master.sh"; do
  if [ ! -e "$candidate" ]; then
    printf '#!/bin/sh\nexit 0\n' > "$candidate" 2>/dev/null && chmod +x "$candidate" || true
  fi
done
