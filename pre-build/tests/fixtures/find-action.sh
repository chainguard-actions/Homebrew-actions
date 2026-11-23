#!/usr/bin/env bash
# Print the path of the shipped pre-build action.yml (the action under test).
# The harness may place it at the workspace root or in a subdirectory
# (e.g. pre-build/), so search for it by its unique name.
set -uo pipefail
match() {
  grep -lE '^name: *"?Pre-bottle-build steps' "$1" 2>/dev/null | head -n1
}
for f in "${GITHUB_WORKSPACE:-.}/action.yml" "${GITHUB_WORKSPACE:-.}/action.yaml" \
         "${GITHUB_WORKSPACE:-.}/pre-build/action.yml" "${GITHUB_WORKSPACE:-.}/pre-build/action.yaml"; do
  if [ -f "$f" ] && [ -n "$(match "$f")" ]; then echo "$f"; exit 0; fi
done
for root in "${GITHUB_WORKSPACE:-.}" "${GITHUB_WORKSPACE:-.}/.." /home/runner/work /github /; do
  [ -d "$root" ] || continue
  found="$(find "$root" -xdev \( -path /proc -o -path /sys \) -prune -o \
    \( -name action.yml -o -name action.yaml \) -type f -print 2>/dev/null \
    | while read -r f; do m="$(match "$f")"; if [ -n "$m" ]; then echo "$m"; break; fi; done)"
  if [ -n "$found" ]; then echo "$found"; exit 0; fi
done
echo "could not locate pre-build action.yml" >&2
exit 1
