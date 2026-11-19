#!/bin/sh
# Fake `brew` used by the setup-ruby tests. Logs every call to $ROOT/calls.log
# and simulates `--prefix ruby`, `--repository`, `install ruby` and
# `vendor-install ruby` by creating a fake ruby + bundle executable.
ROOT="${FAKE_BREW_ROOT:-/tmp/fakebrew}"
mkdir -p "$ROOT"
echo "brew $*" >> "$ROOT/calls.log"

make_ruby() {
  mkdir -p "$1"
  cat > "$1/ruby" <<'EOF'
#!/bin/sh
if [ "$1" = "-e" ]; then
  printf '%s' "3.4.1"
  exit 0
fi
echo "fake ruby $*"
EOF
  chmod +x "$1/ruby"
  cat > "$1/bundle" <<'EOF'
#!/bin/sh
ROOT="${FAKE_BREW_ROOT:-/tmp/fakebrew}"
echo "bundle $* (pwd=$(pwd))" >> "$ROOT/calls.log"
case "$1" in
  check) exit 1 ;;
esac
exit 0
EOF
  chmod +x "$1/bundle"
}

case "$1" in
  --prefix)
    if [ "$2" = "ruby" ]; then echo "$ROOT/opt/ruby"; else echo "$ROOT"; fi
    ;;
  --repository)
    echo "$ROOT/repo"
    ;;
  install)
    if [ "$2" = "ruby" ]; then make_ruby "$ROOT/opt/ruby/bin"; else exit 1; fi
    ;;
  vendor-install)
    if [ "$2" = "ruby" ]; then
      make_ruby "$ROOT/repo/Library/Homebrew/vendor/portable-ruby/current/bin"
    else
      exit 1
    fi
    ;;
  *)
    echo "fake brew: unsupported command: $*" >&2
    exit 1
    ;;
esac
