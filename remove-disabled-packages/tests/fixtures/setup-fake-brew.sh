#!/usr/bin/env bash
# Sets up a fake `brew` on PATH and a fake tap git repository under /tmp/fakebrew
# so the remove-disabled-packages action can run deterministically under act.
set -euo pipefail

ROOT=/tmp/fakebrew
rm -rf "$ROOT"
mkdir -p "$ROOT/bin" "$ROOT/tap" "$ROOT/repo" "$ROOT/info"

# Default (empty) brew info payloads.
echo '{"formulae":[],"casks":[]}' > "$ROOT/info/formula.json"
echo '{"formulae":[],"casks":[]}' > "$ROOT/info/cask.json"

cat > "$ROOT/bin/brew" <<'EOF'
#!/usr/bin/env bash
ROOT=/tmp/fakebrew
echo "fake brew: $*" >&2
case "${1:-}" in
  --repository|--repo)
    if [ $# -ge 2 ]; then echo "$ROOT/tap"; else echo "$ROOT/repo"; fi
    ;;
  --prefix)
    echo "$ROOT"
    ;;
  info)
    type=formula
    for a in "$@"; do
      case "$a" in
        --cask|--casks) type=cask ;;
        --formula|--formulae) type=formula ;;
      esac
    done
    cat "$ROOT/info/$type.json"
    ;;
  *)
    exit 0
    ;;
esac
EOF
chmod +x "$ROOT/bin/brew"
echo "$ROOT/bin" >> "$GITHUB_PATH"

# Ensure a Ruby interpreter >= 3.1 is available (main.rb uses shorthand hash
# syntax). The action's own setup-ruby step cannot run under act, and the apt
# ruby on Ubuntu 22.04 is 3.0, so fetch a prebuilt modern Ruby.
SUDO=""
if [ "$(id -u)" != "0" ] && command -v sudo >/dev/null 2>&1; then SUDO=sudo; fi

ruby_ok() {
  "$1" -e 'exit(Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.1") ? 0 : 1)' >/dev/null 2>&1
}

RUBY_BIN=""
if command -v ruby >/dev/null 2>&1 && ruby_ok "$(command -v ruby)"; then
  RUBY_BIN="$(command -v ruby)"
fi

if [ -z "$RUBY_BIN" ]; then
  # Runtime libs prebuilt rubies may need (best effort).
  ( $SUDO apt-get update -qq || true
    DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq \
      curl ca-certificates libyaml-0-2 libffi8 libssl3 zlib1g libgmp10 >/dev/null 2>&1 || true ) || true

  OS_VER="22.04"
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_VER="${VERSION_ID:-22.04}"
  fi

  # 1) ruby/ruby-builder toolcache builds (used by ruby/setup-ruby).
  for v in 3.3.6 3.3.5 3.2.6 3.4.1; do
    url="https://github.com/ruby/ruby-builder/releases/download/toolcache/ruby-$v-ubuntu-$OS_VER.tar.gz"
    dest="/opt/hostedtoolcache/Ruby/$v"
    echo "Trying $url"
    if curl -fsSL --retry 3 -o /tmp/ruby.tgz "$url"; then
      $SUDO mkdir -p "$dest"
      $SUDO tar -xzf /tmp/ruby.tgz -C "$dest" || continue
      cand="$(find "$dest" -path '*/bin/ruby' -type f | head -n1)"
      if [ -n "$cand" ] && ruby_ok "$cand"; then
        RUBY_BIN="$cand"
        $SUDO touch "$dest/x64.complete" || true
        break
      fi
    fi
  done
fi

if [ -z "$RUBY_BIN" ]; then
  # 2) Homebrew portable ruby (relocatable).
  for v in 3.4.7 3.4.5 3.4.4 3.4.3 3.3.8 3.3.7; do
    url="https://github.com/Homebrew/homebrew-portable-ruby/releases/download/$v/portable-ruby-$v.x86_64_linux.bottle.tar.gz"
    echo "Trying $url"
    if curl -fsSL --retry 3 -o /tmp/pruby.tgz "$url"; then
      mkdir -p "$ROOT/pruby"
      tar -xzf /tmp/pruby.tgz -C "$ROOT/pruby" || continue
      cand="$(find "$ROOT/pruby" -path '*/bin/ruby' -type f | head -n1)"
      if [ -n "$cand" ] && ruby_ok "$cand"; then
        RUBY_BIN="$cand"
        break
      fi
    fi
  done
fi

if [ -z "$RUBY_BIN" ]; then
  echo "ERROR: could not obtain Ruby >= 3.1"
  exit 1
fi

# Put the modern ruby first on PATH via the fake bin dir.
RUBY_DIR="$(dirname "$RUBY_BIN")"
for exe in ruby gem; do
  if [ -x "$RUBY_DIR/$exe" ]; then
    printf '#!/bin/sh\nexec "%s" "$@"\n' "$RUBY_DIR/$exe" > "$ROOT/bin/$exe"
    chmod +x "$ROOT/bin/$exe"
  fi
done
echo "$RUBY_DIR" >> "$GITHUB_PATH"
"$RUBY_BIN" --version
# Provide a "portable ruby" location in the fake brew repository too.
mkdir -p "$ROOT/repo/Library/Homebrew/vendor/portable-ruby/current/bin"
ln -sf "$RUBY_BIN" "$ROOT/repo/Library/Homebrew/vendor/portable-ruby/current/bin/ruby"

# Git identity for commits made by the action.
git config --global user.email "test@example.com"
git config --global user.name "Test User"

# Initialise the fake tap repo.
git -C "$ROOT/tap" init -q
mkdir -p "$ROOT/tap/Formula" "$ROOT/tap/Casks"
echo "# fake tap" > "$ROOT/tap/README.md"
git -C "$ROOT/tap" add -A
git -C "$ROOT/tap" commit -q -m "initial"

# Compute the tap name the action derives from GITHUB_REPOSITORY.
owner="${GITHUB_REPOSITORY%%/*}"
name="${GITHUB_REPOSITORY#*/}"
owner="$(echo "$owner" | tr '[:upper:]' '[:lower:]')"
name="$(echo "$name" | tr '[:upper:]' '[:lower:]')"
name="${name#homebrew-}"
echo "$owner/$name" > "$ROOT/tapname"
echo "Fake tap name: $owner/$name"
