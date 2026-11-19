#!/usr/bin/env bash
# Ensures a Ruby >= 3.1 is first on PATH. Under act the action's
# "$/setup-ruby" step is skipped (invalid uses reference), so main.rb would run
# with the image's system Ruby, which may be too old for its syntax
# (e.g. `type:` keyword shorthand needs Ruby 3.1+).
set -euo pipefail

ruby_ok() {
  "$1" -e 'exit(Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.1") ? 0 : 1)' >/dev/null 2>&1
}

if command -v ruby >/dev/null 2>&1 && ruby_ok ruby; then
  echo "System Ruby is new enough: $(ruby --version)"
  exit 0
fi
echo "System Ruby missing or too old: $(ruby --version 2>/dev/null || echo none)"

case "$(uname -m)" in
  x86_64|amd64) ARCH=x86_64_linux ;;
  aarch64|arm64) ARCH=arm64_linux ;;
  *) echo "Unsupported arch $(uname -m)"; exit 1 ;;
esac

DEST="${RUNNER_TEMP:-/tmp}/portable-ruby"
rm -rf "$DEST"
mkdir -p "$DEST"

AUTH=()
TOKEN="${GITHUB_TOKEN:-${INPUT_TOKEN:-}}"
if [ -n "$TOKEN" ]; then
  AUTH=(-H "Authorization: Bearer $TOKEN")
fi

URLS=""
API_JSON="$(curl -fsSL "${AUTH[@]}" \
  "https://api.github.com/repos/Homebrew/homebrew-portable-ruby/releases?per_page=10" 2>/dev/null || \
  curl -fsSL "https://api.github.com/repos/Homebrew/homebrew-portable-ruby/releases?per_page=10" 2>/dev/null || true)"
if [ -n "$API_JSON" ]; then
  URLS="$(printf '%s' "$API_JSON" | grep -o '"browser_download_url": *"[^"]*'"$ARCH"'[^"]*\.tar\.gz"' \
    | sed 's/.*"\(https[^"]*\)"$/\1/' || true)"
fi
# Static fallbacks in case the API is unreachable.
for v in 3.4.7 3.4.5 3.4.4 3.3.8 3.3.7; do
  URLS="$URLS
https://github.com/Homebrew/homebrew-portable-ruby/releases/download/$v/portable-ruby-$v.$ARCH.bottle.tar.gz"
done

RUBY_BIN=""
while IFS= read -r url; do
  [ -z "$url" ] && continue
  echo "Trying $url"
  if curl -fsSL -o "$DEST/ruby.tar.gz" "$url"; then
    rm -rf "$DEST/x"
    mkdir -p "$DEST/x"
    if tar -xzf "$DEST/ruby.tar.gz" -C "$DEST/x"; then
      candidate="$(find "$DEST/x" -type f -path '*/bin/ruby' | head -n1)"
      if [ -n "$candidate" ] && ruby_ok "$candidate"; then
        RUBY_BIN="$candidate"
        break
      fi
    fi
  fi
done <<< "$URLS"

if [ -z "$RUBY_BIN" ]; then
  echo "Portable Ruby download failed; trying apt"
  for pkg in ruby3.3 ruby3.2 ruby3.1 ruby; do
    (sudo -n apt-get install -y "$pkg" || apt-get install -y "$pkg") >/dev/null 2>&1 || continue
    for b in /usr/bin/ruby3.3 /usr/bin/ruby3.2 /usr/bin/ruby3.1 /usr/bin/ruby; do
      if [ -x "$b" ] && ruby_ok "$b"; then
        mkdir -p "$DEST/bin"
        ln -sf "$b" "$DEST/bin/ruby"
        RUBY_BIN="$DEST/bin/ruby"
        break 2
      fi
    done
  done
fi

if [ -z "$RUBY_BIN" ]; then
  echo "FAIL: could not provision Ruby >= 3.1"
  exit 1
fi

echo "Using $("$RUBY_BIN" --version)"
dirname "$RUBY_BIN" >> "$GITHUB_PATH"
