#!/usr/bin/env bash
# Sets up a fake `brew`, a Ruby >= 3.1 and an empty tap git repository so the
# remove-disabled-packages action can be exercised without a real Homebrew.
#
# Layout (all under $RUNNER_TEMP/rdp):
#   bin/brew          fake brew (logs calls to brew.log)
#   prefix/           fake `brew --repository` (no args) / `--prefix`
#   tap/              fake tap repository (`brew --repository <tap>`)
#   formulae.json     returned by `brew info --formula`
#   casks.json        returned by `brew info --cask`
set -euo pipefail

BASE="${RUNNER_TEMP:-/tmp}/rdp"
rm -rf "$BASE"
mkdir -p "$BASE/bin" "$BASE/prefix" "$BASE/tap/Formula"
echo '{"formulae":[]}' > "$BASE/formulae.json"
echo '{"casks":[]}' > "$BASE/casks.json"
: > "$BASE/brew.log"

cat > "$BASE/bin/brew" <<EOF
#!/bin/sh
printf '%s\n' "\$*" >> "$BASE/brew.log"
case "\$1" in
  --repository|--repo)
    if [ -n "\$2" ]; then
      printf '%s\n' "$BASE/tap"
    else
      printf '%s\n' "$BASE/prefix"
    fi
    ;;
  --prefix|--cellar|--cache)
    printf '%s\n' "$BASE/prefix"
    ;;
  info)
    case " \$* " in
      *' --formula '*) cat "$BASE/formulae.json" ;;
      *' --cask '*) cat "$BASE/casks.json" ;;
    esac
    ;;
  *)
    exit 0
    ;;
esac
EOF
chmod +x "$BASE/bin/brew"

# --- Find a Ruby >= 3.1 (main.rb uses Ruby 3.1 syntax) ---
ruby_ok() {
  "$1" -e 'exit(Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.1") ? 0 : 1)' >/dev/null 2>&1
}

RUBY=""
candidates=()
if command -v ruby >/dev/null 2>&1; then candidates+=("$(command -v ruby)"); fi
for r in $(ls -d /opt/hostedtoolcache/Ruby/*/*/bin/ruby 2>/dev/null | sort -rV); do
  candidates+=("$r")
done
for r in "${candidates[@]}"; do
  if ruby_ok "$r"; then RUBY="$r"; break; fi
done

if [ -z "$RUBY" ]; then
  echo "No Ruby >= 3.1 found; downloading Homebrew portable Ruby"
  case "$(uname -m)" in
    aarch64|arm64) arch=arm64_linux ;;
    *) arch=x86_64_linux ;;
  esac
  auth=()
  if [ -n "${GITHUB_TOKEN:-}" ]; then auth=(-H "Authorization: Bearer $GITHUB_TOKEN"); fi
  url="$(curl -fsSL "${auth[@]}" https://api.github.com/repos/Homebrew/homebrew-portable-ruby/releases/latest \
    | grep -o "\"browser_download_url\": *\"[^\"]*${arch}[^\"]*\"" | head -1 \
    | sed 's/.*"\(https[^"]*\)"$/\1/')"
  echo "portable ruby url: $url"
  mkdir -p "$BASE/portable"
  curl -fsSL "$url" -o "$BASE/portable/ruby.tar.gz"
  tar -xzf "$BASE/portable/ruby.tar.gz" -C "$BASE/portable"
  RUBY="$(ls -d "$BASE"/portable/portable-ruby/*/bin/ruby | head -1)"
fi

if [ -z "$RUBY" ] || ! ruby_ok "$RUBY"; then
  echo "FAIL: could not provide a Ruby >= 3.1"
  exit 1
fi
RUBY_BIN="$(dirname "$RUBY")"
echo "Using Ruby: $RUBY ($("$RUBY" -v))"

# Make the fake portable-ruby location point at this Ruby too, in case the
# setup-ruby step adds it to PATH.
mkdir -p "$BASE/prefix/Library/Homebrew/vendor/portable-ruby"
ln -sfn "$(dirname "$RUBY_BIN")" "$BASE/prefix/Library/Homebrew/vendor/portable-ruby/current"

# Later GITHUB_PATH entries take precedence.
echo "$RUBY_BIN" >> "$GITHUB_PATH"
echo "$BASE/bin" >> "$GITHUB_PATH"

git -C "$BASE/tap" init --quiet
echo "RDP_BASE=$BASE" >> "$GITHUB_ENV"

# Tap name the action derives from GITHUB_REPOSITORY.
owner="${GITHUB_REPOSITORY%%/*}"
name="${GITHUB_REPOSITORY#*/}"
name="${name,,}"
echo "RDP_TAP=${owner,,}/${name#homebrew-}" >> "$GITHUB_ENV"
