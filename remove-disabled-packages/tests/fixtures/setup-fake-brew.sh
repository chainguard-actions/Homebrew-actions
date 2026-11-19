#!/usr/bin/env bash
# Sets up a fake `brew` on PATH plus a local tap git repository so that the
# remove-disabled-packages action can run without a real Homebrew tap.
#
# Usage: setup-fake-brew.sh <subdir>...   (e.g. Formula Casks)
#
# After running, populate:
#   $FAKE_ROOT/formulae.json  ({"formulae":[...]})
#   $FAKE_ROOT/casks.json     ({"casks":[...]})
#   files under $TAP_DIR, then run commit-tap.sh
set -euo pipefail

FAKE_ROOT="${RUNNER_TEMP:-/tmp}/fake-brew"
TAP_DIR="$FAKE_ROOT/tap"
rm -rf "$FAKE_ROOT"
mkdir -p "$FAKE_ROOT/bin" "$TAP_DIR"

for sub in "$@"; do
  mkdir -p "$TAP_DIR/$sub"
done

echo '{"formulae":[]}' > "$FAKE_ROOT/formulae.json"
echo '{"casks":[]}' > "$FAKE_ROOT/casks.json"
: > "$FAKE_ROOT/brew.log"

REAL_BREW="$(command -v brew || true)"

cat > "$FAKE_ROOT/bin/brew" <<EOF
#!/bin/sh
echo "\$*" >> "$FAKE_ROOT/brew.log"
case "\$1" in
  --repository|--repo)
    if [ -n "\$2" ]; then
      echo "$TAP_DIR"
      exit 0
    fi
    ;;
  info)
    case " \$* " in
      *" --formula "*) cat "$FAKE_ROOT/formulae.json"; exit 0 ;;
      *" --cask "*) cat "$FAKE_ROOT/casks.json"; exit 0 ;;
    esac
    ;;
esac
if [ -n "$REAL_BREW" ]; then
  exec "$REAL_BREW" "\$@"
fi
exit 0
EOF
chmod +x "$FAKE_ROOT/bin/brew"

git -C "$TAP_DIR" init --quiet
git -C "$TAP_DIR" config user.email "test@example.com"
git -C "$TAP_DIR" config user.name "Test User"
git -C "$TAP_DIR" config commit.gpgsign false

# Compute the tap name the action derives from GITHUB_REPOSITORY (used only to
# build fixture data; never asserted on).
OWNER="${GITHUB_REPOSITORY%%/*}"
NAME="${GITHUB_REPOSITORY#*/}"
TARGET_TAP="$(printf '%s' "$OWNER" | tr '[:upper:]' '[:lower:]')/$(printf '%s' "$NAME" | tr '[:upper:]' '[:lower:]' | sed 's/^homebrew-//')"

# Best-effort Ruby fallback if the runner image has none.
if ! command -v ruby >/dev/null 2>&1; then
  (sudo -n apt-get update -y && sudo -n apt-get install -y ruby) >/dev/null 2>&1 || \
    (apt-get update -y && apt-get install -y ruby) >/dev/null 2>&1 || true
fi

{
  echo "FAKE_ROOT=$FAKE_ROOT"
  echo "TAP_DIR=$TAP_DIR"
  echo "TARGET_TAP=$TARGET_TAP"
} >> "$GITHUB_ENV"
echo "$FAKE_ROOT/bin" >> "$GITHUB_PATH"

echo "Fake brew set up at $FAKE_ROOT (tap: $TARGET_TAP)"
