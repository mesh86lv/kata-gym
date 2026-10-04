#!/usr/bin/env bash
#
# Select the current kata or project and remember it in .current.
#
# Usage:
#   ./scripts/pick.sh [lang] [kind]
#
# Examples:
#   ./scripts/pick.sh              # fully interactive
#   ./scripts/pick.sh go           # only the kind and the item are asked
#   ./scripts/pick.sh go kata      # only the item is asked

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$ROOT/scripts/lib.sh"

lang="$(choose_value "${1:-}" language "${KATA_LANGUAGES[@]}")" || exit $?
kind="$(choose_value "${2:-}" what "${KATA_KINDS[@]}")" || exit $?

base="$(item_base "$lang" "$kind")"
if [ ! -d "$base" ]; then
  echo "no such directory: $base" >&2
  exit 1
fi

mapfile -t items < <(item_names "$lang" "$kind")
if [ "${#items[@]}" -eq 0 ]; then
  if [ "$kind" = "kata" ]; then
    hint="just new-kata $lang <id> <name>"
  else
    hint="just new-project $lang <name>"
  fi
  echo "$base is empty — create one with '$hint'" >&2
  exit 1
fi

name="$(printf '%s\n' "${items[@]}" | gum choose --header "item:")" || exit 130
[ -n "$name" ] || exit 130

path="$(item_path "$lang" "$kind" "$name")"
printf '%s\t%s\t%s\t%s\n' "$lang" "$kind" "$name" "$path" >"$ROOT/.current"
echo "→ $lang / $kind / $name"
