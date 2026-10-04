#!/usr/bin/env bash
#
# Delete a kata or project.
#
# Usage:
#   ./scripts/delete.sh [lang] [kind] [id] [-y|--yes]
#
# Examples:
#   ./scripts/delete.sh                       # fully interactive
#   ./scripts/delete.sh rust kata 0002        # asks for confirmation
#   ./scripts/delete.sh rust kata 0002 --yes  # no confirmation
#
# Deleting a Rust kata removes the single module file and its `pub mod ...;`
# line in rust/katas/src/lib.rs. Projects need no bookkeeping: pnpm, uv, cargo
# and go all discover them through globs.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$ROOT/scripts/lib.sh"

confirmed=0
args=()
for arg in "$@"; do
  case "$arg" in
  -y | --yes | yes) confirmed=1 ;;
  *) args+=("$arg") ;;
  esac
done

lang="$(choose_value "${args[0]:-}" language "${KATA_LANGUAGES[@]}")" || exit $?
kind="$(choose_value "${args[1]:-}" what "${KATA_KINDS[@]}")" || exit $?
id="${args[2]:-}"

if [ -n "$id" ]; then
  path="$(find_item_by_id "$lang" "$kind" "$id")" || true
  if [ -z "$path" ]; then
    echo "not found: $lang $kind '$id' (see 'just list $lang $kind')" >&2
    exit 1
  fi
else
  base="$(item_base "$lang" "$kind")"
  mapfile -t items < <(item_names "$lang" "$kind")
  if [ "${#items[@]}" -eq 0 ]; then
    echo "$base has no $kind to delete" >&2
    exit 1
  fi
  name="$(printf '%s\n' "${items[@]}" | gum choose --header "delete:")" || exit 130
  [ -n "$name" ] || exit 130
  path="$(item_path "$lang" "$kind" "$name")"
fi

name="$(item_name "$path")"

if [ "$confirmed" -ne 1 ]; then
  if ! gum confirm "Delete $lang $kind '$name'?"; then
    echo "aborted" >&2
    exit 1
  fi
fi

if is_rust_kata "$lang" "$kind"; then
  rm -f "$path"
  lib="$ROOT/rust/katas/src/lib.rs"
  if [ -f "$lib" ]; then
    sed -i "/^pub mod ${name};$/d" "$lib"
  fi
else
  rm -rf "$path"
fi

if [ "$lang" = "rust" ]; then
  bash "$ROOT/scripts/rust-sync.sh"
fi

echo "deleted $lang $kind $name ($path)"

if [ "$(current_path)" = "$path" ]; then
  rm -f "$ROOT/.current"
  echo "cleared the current selection"
fi
