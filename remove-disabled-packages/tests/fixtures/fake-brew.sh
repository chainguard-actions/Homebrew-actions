#!/usr/bin/env bash
# Test helper for the remove-disabled-packages action.
#
#   fake-brew.sh init    -> install a fake `brew`, ensure a Ruby >= 3.1 is on PATH,
#                           create an empty tap directory and export env vars.
#   fake-brew.sh commit  -> git init + commit everything in the tap directory.
#
# The fake brew answers:
#   brew --repository <repo>   -> $TAP_DIRECTORY
#   brew --repository          -> $FAKE_BREW_REPO (fake Homebrew repository)
#   brew info --json=v2 --formula -> $FORMULA_JSON
#   brew info --json=v2 --cask    -> $CASK_JSON
#   anything else              -> exit 0 (e.g. calls made by setup-ruby)
set -euo pipefail

ROOT=/tmp/fake-brew

case "${1:-}" in
init)
  rm -rf "$ROOT"
  mkdir -p "$ROOT/bin" "$ROOT/tap" "$ROOT/repo/Library/Homebrew/vendor"

  # ---- Ruby (main.rb needs Ruby >= 3.1 for `key:` hash shorthand) ----
  RUBY_BIN_DIR=""
  if command -v ruby >/dev/null 2>&1 && ruby -e 'exit(Gem::Version.new(RUBY_VERSION) >= Gem::Version.new("3.1") ? 0 : 1)'; then
    RUBY_BIN_DIR="$(dirname "$(command -v ruby)")"
    echo "Using system ruby: $(ruby --version)"
  else
    case "$(uname -m)" in
      x86_64|amd64) ARCH=x86_64_linux ;;
      aarch64|arm64) ARCH=arm64_linux ;;
      *) ARCH="$(uname -m)_linux" ;;
    esac
    AUTH=()
    if [ -n "${GH_TOKEN:-}" ]; then AUTH=(-H "Authorization: Bearer $GH_TOKEN"); fi
    URL="$(curl -fsSL "${AUTH[@]}" https://api.github.com/repos/Homebrew/homebrew-portable-ruby/releases/latest \
      | grep -oE '"browser_download_url": *"[^"]+'"$ARCH"'[^"]*\.tar\.gz"' \
      | head -n1 | sed -E 's/.*"(https[^"]+)"/\1/')" || true
    if [ -n "$URL" ]; then
      echo "Downloading portable ruby: $URL"
      mkdir -p "$ROOT/portable"
      curl -fsSL "$URL" -o "$ROOT/portable-ruby.tar.gz"
      tar -xzf "$ROOT/portable-ruby.tar.gz" -C "$ROOT/portable"
      RUBY_EXE="$(find "$ROOT/portable" -type f -path '*/bin/ruby' | head -n1)"
      RUBY_BIN_DIR="$(dirname "$RUBY_EXE")"
    else
      echo "Could not locate portable ruby; falling back to apt"
      SUDO=""
      if [ "$(id -u)" -ne 0 ]; then SUDO=sudo; fi
      $SUDO apt-get update -qq
      $SUDO apt-get install -y -qq ruby
      RUBY_BIN_DIR="$(dirname "$(command -v ruby)")"
    fi
    "$RUBY_BIN_DIR/ruby" --version
  fi

  # Fake Homebrew repository layout in case setup-ruby inspects it.
  mkdir -p "$ROOT/repo/Library/Homebrew/vendor/portable-ruby/current/bin"
  ln -sf "$RUBY_BIN_DIR/ruby" "$ROOT/repo/Library/Homebrew/vendor/portable-ruby/current/bin/ruby"
  "$RUBY_BIN_DIR/ruby" -e 'print RUBY_VERSION' > "$ROOT/repo/Library/Homebrew/vendor/portable-ruby-version"

  # ---- fake brew ----
  cat > "$ROOT/bin/brew" <<'EOF'
#!/bin/sh
echo "brew $*" >> "${BREW_LOG:-/tmp/fake-brew/brew.log}"
case "$1" in
  --repository|--repo)
    if [ -n "$2" ]; then echo "$TAP_DIRECTORY"; else echo "$FAKE_BREW_REPO"; fi
    ;;
  --prefix)
    echo "$FAKE_BREW_REPO"
    ;;
  info)
    case " $* " in
      *" --formula "*) cat "$FORMULA_JSON" ;;
      *" --cask "*) cat "$CASK_JSON" ;;
      *) echo '{}' ;;
    esac
    ;;
  ruby)
    shift
    exec ruby "$@"
    ;;
esac
exit 0
EOF
  chmod +x "$ROOT/bin/brew"
  : > "$ROOT/brew.log"
  echo '{"formulae":[]}' > "$ROOT/formulae.json"
  echo '{"casks":[]}' > "$ROOT/casks.json"

  # Tap name exactly as main.rb derives it from GITHUB_REPOSITORY.
  owner="${GITHUB_REPOSITORY%%/*}"
  name="${GITHUB_REPOSITORY#*/}"
  owner="$(echo "$owner" | tr '[:upper:]' '[:lower:]')"
  name="$(echo "$name" | tr '[:upper:]' '[:lower:]')"
  name="${name#homebrew-}"
  TAP_NAME="$owner/$name"
  echo "Target tap: $TAP_NAME"

  {
    echo "TAP_NAME=$TAP_NAME"
    echo "TAP_DIRECTORY=$ROOT/tap"
    echo "FAKE_BREW_REPO=$ROOT/repo"
    echo "FORMULA_JSON=$ROOT/formulae.json"
    echo "CASK_JSON=$ROOT/casks.json"
    echo "BREW_LOG=$ROOT/brew.log"
    echo "OLD_DATE=$(date -u -d '13 months ago' +%F)"
    echo "RECENT_DATE=$(date -u -d '6 months ago' +%F)"
    echo "GIT_AUTHOR_NAME=BrewTestBot"
    echo "GIT_AUTHOR_EMAIL=brew-test-bot@brew.sh"
    echo "GIT_COMMITTER_NAME=BrewTestBot"
    echo "GIT_COMMITTER_EMAIL=brew-test-bot@brew.sh"
  } >> "$GITHUB_ENV"

  # Prepend so the fake brew and the chosen ruby win over anything else.
  echo "$RUBY_BIN_DIR" >> "$GITHUB_PATH"
  echo "$ROOT/bin" >> "$GITHUB_PATH"
  ;;
commit)
  git -C "$ROOT/tap" init --quiet
  git -C "$ROOT/tap" add --all
  git -C "$ROOT/tap" commit --allow-empty --quiet --message "Add fixtures"
  git -C "$ROOT/tap" log --oneline
  ;;
*)
  echo "usage: $0 init|commit" >&2
  exit 1
  ;;
esac
