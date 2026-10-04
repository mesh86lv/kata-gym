#!/usr/bin/env bash
#
# List katas and projects.
#
# Usage:
#   ./scripts/list.sh [lang] [kind]
#
# Examples:
#   ./scripts/list.sh              # every language, katas and projects
#   ./scripts/list.sh go           # only go
#   ./scripts/list.sh go kata      # only go katas
#
# The currently selected item is marked with '*'.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$ROOT/scripts/lib.sh"

if [ -n "${1:-}" ]; then
  langs=("$1")
else
  langs=("${KATA_LANGUAGES[@]}")
fi

if [ -n "${2:-}" ]; then
  kinds=("$2")
else
  kinds=("${KATA_KINDS[@]}")
fi

for lang in "${langs[@]}"; do
  if ! is_supported_lang "$lang"; then
    echo "unknown language: $lang (expected one of: ${KATA_LANGUAGES[*]})" >&2
    exit 1
  fi
done

for kind in "${kinds[@]}"; do
  if ! is_supported_kind "$kind"; then
    echo "unknown kind: $kind (expected one of: ${KATA_KINDS[*]})" >&2
    exit 1
  fi
done

selection="$(current_path)"

# label_for <kind> — plural heading used in the listing.
label_for() {
  case "$1" in
  kata) printf '%s\n' "katas" ;;
  project) printf '%s\n' "projects" ;;
  esac
}

for lang in "${langs[@]}"; do
  echo "$lang"
  for kind in "${kinds[@]}"; do
    mapfile -t items < <(item_names "$lang" "$kind")
    echo "  $(label_for "$kind") (${#items[@]})"
    if [ "${#items[@]}" -eq 0 ]; then
      echo "    (none)"
      continue
    fi
    for name in "${items[@]}"; do
      path="$(item_path "$lang" "$kind" "$name")"
      marker=""
      if [ -n "$selection" ] && [ "$path" = "$selection" ]; then
        marker=" *"
      fi
      printf '    %s%s\n' "$name" "$marker"
    done
  done
done
