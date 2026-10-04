#!/usr/bin/env bash
#
# Reconcile the `members` array of rust/Cargo.toml with the directories that
# actually exist under rust/projects/.
#
# Cargo does not tolerate a stale member: a path listed but missing breaks the
# whole workspace, including `cargo test -p katas`. And a glob is not an option
# either — when `members` contains a glob that matches nothing, Cargo falls back
# to the literal pattern and fails the same way (this repository has had zero
# Rust projects more than once).
#
# The script is idempotent and silent unless it changes something.
#
# Usage: ./scripts/rust-sync.sh

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

manifest="$ROOT/rust/Cargo.toml"
[ -f "$manifest" ] || exit 0

projects=""
for dir in "$ROOT"/rust/projects/*/; do
  [ -d "$dir" ] || continue
  [ -f "$dir/Cargo.toml" ] || continue
  name="$(basename "$dir")"
  if [ -n "$projects" ]; then
    projects="$projects, \"projects/$name\""
  else
    projects="\"projects/$name\""
  fi
done

if [ -n "$projects" ]; then
  replacement="members = [\"katas\", $projects]"
else
  replacement="members = [\"katas\"]"
fi

tmp="$manifest.tmp"
awk -v repl="$replacement" '
  /^[[:space:]]*members[[:space:]]*=/ {
    print repl
    if ($0 !~ /\]/) {
      skip = 1
    }
    next
  }
  skip {
    if ($0 ~ /\]/) {
      skip = 0
    }
    next
  }
  { print }
' "$manifest" >"$tmp"

if cmp -s "$manifest" "$tmp"; then
  rm -f "$tmp"
else
  mv "$tmp" "$manifest"
  echo "rust/Cargo.toml: ${replacement#members = }"
fi
