#!/usr/bin/env bash
# Sets up a fake `brew` on PATH plus the Homebrew layout the action expects
# (portable Ruby, API cache). Real Homebrew is not available in act images.
# Usage: setup-fake-brew.sh [preinstalled formula ...]
set -euo pipefail

ROOT="${RUNNER_TEMP:-/tmp}/fakebrew"
rm -rf "$ROOT"
mkdir -p "$ROOT/bin" "$ROOT/prefix" "$ROOT/cache/api" \
  "$ROOT/repo/Library/Homebrew/vendor/portable-ruby/current/bin"
: > "$ROOT/log"
: > "$ROOT/installed"
for f in "$@"; do
  echo "$f" >> "$ROOT/installed"
done

# Ensure a real ruby exists to stand in for Homebrew's portable Ruby.
if ! command -v ruby >/dev/null 2>&1; then
  SUDO=""
  if [ "$(id -u)" != "0" ] && command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  fi
  export DEBIAN_FRONTEND=noninteractive
  $SUDO apt-get update -y >/dev/null
  $SUDO apt-get install -y --no-install-recommends ruby >/dev/null
fi
ln -sf "$(command -v ruby)" \
  "$ROOT/repo/Library/Homebrew/vendor/portable-ruby/current/bin/ruby"

# Public formula API cache (array payload).
cat > "$ROOT/cache/api/formula.jws.json" <<'EOF'
{"payload":"[{\"name\":\"jq\",\"versions\":{\"stable\":\"1.7.1\"},\"revision\":0},{\"name\":\"wget\",\"versions\":{\"stable\":\"1.24.5\"},\"revision\":1},{\"name\":\"tree\",\"versions\":{\"stable\":\"2.2.1\"},\"revision\":0}]","signatures":[]}
EOF

cat > "$ROOT/bin/brew" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
echo "brew $*" >> "$ROOT/log"
cmd="${1:-}"
[ $# -gt 0 ] && shift
case "$cmd" in
  --prefix) echo "$ROOT/prefix" ;;
  --repository) echo "$ROOT/repo" ;;
  --cache) echo "$ROOT/cache" ;;
  list)
    if [ -s "$ROOT/installed" ]; then sort -u "$ROOT/installed"; fi
    ;;
  install)
    for a in "$@"; do
      case "$a" in
        -*) ;;
        *) echo "$a" >> "$ROOT/installed"; mkdir -p "$ROOT/prefix/Cellar/$a" ;;
      esac
    done
    ;;
  upgrade) ;;
  test-bot) : > "$ROOT/installed" ;;
  bundle)
    sub="install"
    if [ $# -gt 0 ] && [[ "$1" != -* ]]; then sub="$1"; shift; fi
    file="Brewfile"
    while [ $# -gt 0 ]; do
      case "$1" in
        --file) file="$2"; shift 2 ;;
        --file=*) file="${1#--file=}"; shift ;;
        *) shift ;;
      esac
    done
    brews="$(sed -nE 's/^[[:space:]]*brew[[:space:]]+"([^"]+)".*/\1/p' "$file")"
    case "$sub" in
      list) echo "$brews" ;;
      check) exit 1 ;;
      install)
        for b in $brews; do
          echo "$b" >> "$ROOT/installed"
          mkdir -p "$ROOT/prefix/Cellar/$b"
        done
        ;;
      *) echo "fake brew bundle: unsupported $sub" >&2; exit 1 ;;
    esac
    ;;
  *) echo "fake brew: unsupported command: $cmd $*" >&2; exit 1 ;;
esac
EOF
chmod +x "$ROOT/bin/brew"

echo "$ROOT/bin" >> "$GITHUB_PATH"
echo "FAKE_BREW_ROOT=$ROOT" >> "$GITHUB_ENV"

# The action calls "$GITHUB_ACTION_PATH/../deprecate-master.sh" which lives in
# the parent Homebrew/actions repo; provide a no-op stub if it is absent.
for dir in "${GITHUB_WORKSPACE}" "$(pwd)"; do
  stub="$(dirname "$dir")/deprecate-master.sh"
  if [ ! -e "$stub" ]; then
    printf '#!/bin/sh\nexit 0\n' > "$stub" 2>/dev/null && chmod +x "$stub" || true
  fi
done

echo "Fake brew ready at $ROOT"
