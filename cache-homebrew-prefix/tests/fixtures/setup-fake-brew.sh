#!/usr/bin/env bash
# Sets up a fake `brew` executable on PATH for testing cache-homebrew-prefix.
# Usage: setup-fake-brew.sh [preinstalled-formula ...]
set -euo pipefail

ROOT="${RUNNER_TEMP:-/tmp}/fake-brew"
rm -rf "$ROOT"
mkdir -p "$ROOT/bin" "$ROOT/prefix" "$ROOT/cache/api" \
  "$ROOT/repo/Library/Homebrew/vendor/portable-ruby/current/bin"
: > "$ROOT/installed"
: > "$ROOT/calls.log"
for f in "$@"; do
  echo "$f" >> "$ROOT/installed"
done

# Fake Homebrew public API cache consumed by version-hash.rb
cat > "$ROOT/cache/api/formula.jws.json" <<'EOF'
{"payload":"[{\"name\":\"hello\",\"versions\":{\"stable\":\"2.12\"},\"revision\":0},{\"name\":\"jq\",\"versions\":{\"stable\":\"1.7.1\"},\"revision\":1},{\"name\":\"wget\",\"versions\":{\"stable\":\"1.24.5\"},\"revision\":0}]"}
EOF

# Portable ruby -> system ruby
if ! command -v ruby >/dev/null 2>&1; then
  SUDO=""
  if [ "$(id -u)" != "0" ] && command -v sudo >/dev/null 2>&1; then SUDO="sudo"; fi
  $SUDO apt-get update -qq
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq ruby >/dev/null
fi
SYS_RUBY="$(command -v ruby)"
cat > "$ROOT/repo/Library/Homebrew/vendor/portable-ruby/current/bin/ruby" <<EOF
#!/bin/sh
exec "$SYS_RUBY" "\$@"
EOF
chmod +x "$ROOT/repo/Library/Homebrew/vendor/portable-ruby/current/bin/ruby"

cat > "$ROOT/bin/brew" <<'EOF'
#!/usr/bin/env bash
ROOT="__ROOT__"
echo "$*" >> "$ROOT/calls.log"

brewfile_brews() {
  local file="Brewfile" prev=""
  for a in "$@"; do
    if [ "$prev" = "--file" ]; then file="$a"; fi
    prev="$a"
  done
  sed -nE 's/^[[:space:]]*brew[[:space:]]+"([^"]+)".*/\1/p' "$file"
}

case "${1:-}" in
  --prefix) echo "$ROOT/prefix" ;;
  --repository) echo "$ROOT/repo" ;;
  --cache) echo "$ROOT/cache" ;;
  list) cat "$ROOT/installed" ;;
  install)
    shift
    for a in "$@"; do
      case "$a" in
        -*) ;;
        *) echo "$a" >> "$ROOT/installed"; touch "$ROOT/prefix/$a" ;;
      esac
    done
    ;;
  upgrade) ;;
  test-bot) : > "$ROOT/installed" ;;
  bundle)
    shift
    case "${1:-}" in
      list) shift; brewfile_brews "$@" ;;
      check) exit 1 ;;
      *)
        for p in $(brewfile_brews "$@"); do
          echo "$p" >> "$ROOT/installed"
          touch "$ROOT/prefix/$p"
        done
        ;;
    esac
    ;;
  *) echo "fake brew: unsupported command: $*" >&2; exit 1 ;;
esac
EOF
sed -i "s|__ROOT__|$ROOT|" "$ROOT/bin/brew"
chmod +x "$ROOT/bin/brew"

# The action calls "$GITHUB_ACTION_PATH/../deprecate-master.sh"; provide a no-op if absent.
DEP="${GITHUB_WORKSPACE}/../deprecate-master.sh"
if [ ! -e "$DEP" ]; then
  printf '#!/bin/sh\nexit 0\n' > "$DEP" 2>/dev/null && chmod +x "$DEP" || true
fi

echo "$ROOT/bin" >> "$GITHUB_PATH"
echo "FAKE_BREW_ROOT=$ROOT" >> "$GITHUB_ENV"
echo "Fake brew installed at $ROOT/bin/brew"
