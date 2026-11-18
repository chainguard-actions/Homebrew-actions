#!/usr/bin/env bash
# Sets up a fake Homebrew installation (brew + portable ruby) so the
# cache-homebrew-prefix action can be exercised under act without a real
# Homebrew install. All brew invocations are logged to /tmp/fakebrew/calls.log.
set -euo pipefail

STATE=/tmp/fakebrew
rm -rf "$STATE"
mkdir -p "$STATE/bin" "$STATE/prefix/bin" \
  "$STATE/repo/Library/Homebrew/vendor/portable-ruby/current/bin"
echo "fake prefix content" > "$STATE/prefix/bin/README"
: > "$STATE/calls.log"

cat > "$STATE/bin/brew" <<'EOF'
#!/usr/bin/env bash
STATE=/tmp/fakebrew
echo "$*" >> "$STATE/calls.log"
case "${1:-}" in
  --prefix) echo "$STATE/prefix" ;;
  --repository) echo "$STATE/repo" ;;
  list)
    if [[ -f "$STATE/installed" ]]; then cat "$STATE/installed"; fi
    ;;
  test-bot)
    rm -f "$STATE/installed"
    ;;
  bundle)
    file="${@: -1}"
    case "${2:-}" in
      list)
        sed -nE 's/^[[:space:]]*brew[[:space:]]+"([^"]+)".*/\1/p' "$file"
        ;;
      check)
        exit 1
        ;;
      *)
        :
        ;;
    esac
    ;;
  install|upgrade) : ;;
  *) : ;;
esac
exit 0
EOF
chmod +x "$STATE/bin/brew"

cat > "$STATE/repo/Library/Homebrew/vendor/portable-ruby/current/bin/ruby" <<'EOF'
#!/usr/bin/env bash
# Fake ruby: first arg is the version-hash.rb script path; verify it exists.
script="$1"
shift
if [[ ! -f "$script" ]]; then
  echo "fake ruby: script not found: $script" >&2
  exit 3
fi
echo "$script" > /tmp/fakebrew/ruby-script
printf 'fakehash-%s\n' "$(echo "$*" | tr ' ' '-')"
EOF
chmod +x "$STATE/repo/Library/Homebrew/vendor/portable-ruby/current/bin/ruby"

echo "$STATE/bin" >> "$GITHUB_PATH"

# The action's first step calls "$GITHUB_ACTION_PATH/../deprecate-master.sh",
# which lives in the parent Homebrew/actions repo. Provide a no-op if absent.
for base in "$GITHUB_WORKSPACE" "${GITHUB_ACTION_PATH:-$GITHUB_WORKSPACE}"; do
  target="$base/../deprecate-master.sh"
  if [[ ! -e "$target" ]]; then
    printf '#!/bin/sh\nexit 0\n' > "$target" 2>/dev/null && chmod +x "$target" || true
  fi
done
