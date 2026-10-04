#!/usr/bin/env bash
#
# Act on the current selection stored in .current.
#
# Usage:
#   ./scripts/action.sh <run|test|open|status|watch|clear>
#   ./scripts/action.sh --one <lang> <kind> <id> <action>
#
# `run` on a kata means "run its tests with output": a kata has no entry point
# of its own, the test suite is the entry point.

set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib.sh
source "$ROOT/scripts/lib.sh"

# `clear` drops the current selection and does not need one to begin with.
if [ "${1:-}" = "clear" ]; then
  rm -f "$ROOT/.current"
  echo "selection cleared"
  exit 0
fi

if [ "${1:-}" = "--one" ]; then
  lang="${2:?usage: action.sh --one <lang> <kind> <id> <action>}"
  kind="${3:?usage: action.sh --one <lang> <kind> <id> <action>}"
  id="${4:?usage: action.sh --one <lang> <kind> <id> <action>}"
  action="${5:?usage: action.sh --one <lang> <kind> <id> <action>}"

  path="$(find_item_by_id "$lang" "$kind" "$id")" || true
  if [ -z "$path" ]; then
    echo "not found: $lang $kind '$id' (see 'just list $lang $kind')" >&2
    exit 1
  fi
  name="$(item_name "$path")"
else
  action="${1:?usage: action.sh <run|test|open|status|watch|clear>|--one <lang> <kind> <id> <action>}"
  if [ ! -f "$ROOT/.current" ]; then
    # `status` is a query, so an empty selection is a valid answer, not an error.
    if [ "$action" = "status" ]; then
      echo "nothing selected"
      exit 0
    fi
    echo "nothing selected — run 'just pick' first" >&2
    exit 1
  fi
  IFS=$'\t' read -r lang kind name path <"$ROOT/.current"

  if [ "$action" != "status" ] && [ ! -e "$path" ]; then
    echo "the selected item no longer exists: $path" >&2
    echo "run 'just pick' to choose again, or 'just clear' to drop the selection" >&2
    exit 1
  fi
fi

case "$action" in
status)
  printf 'lang=%s\nkind=%s\nname=%s\npath=%s\n' "$lang" "$kind" "$name" "$path"
  if [ ! -e "$path" ]; then
    echo "warning: that item no longer exists — run 'just pick' or 'just clear'" >&2
  fi
  exit 0
  ;;

open)
  case "$lang:$kind" in
  rust:kata) exec "${EDITOR:-code}" "$path" "$ROOT/rust/katas/src/lib.rs" ;;
  go:kata) exec "${EDITOR:-code}" "$path/solution.go" ;;
  *) exec "${EDITOR:-code}" "$path" ;;
  esac
  ;;

test)
  case "$lang:$kind" in
  node:kata) (cd "$path" && node --test) ;;
  node:project) (cd "$path" && pnpm test) ;;
  python:kata) (cd "$path" && uv run pytest -q) ;;
  python:project) (cd "$path" && uv run pytest -q) ;;
  rust:kata) (cd "$ROOT/rust" && cargo test -p katas "$name") ;;
  rust:project) (cd "$path" && cargo test) ;;
  go:kata) (cd "$path" && go test ./...) ;;
  go:project) (cd "$path" && go test ./...) ;;
  esac
  ;;

run)
  case "$lang:$kind" in
  # Katas: "run" == "test" with output.
  node:kata) (cd "$path" && node --test) ;;
  python:kata) (cd "$path" && uv run pytest -q -s) ;;
  rust:kata) (cd "$ROOT/rust" && cargo test -p katas "$name" -- --nocapture) ;;
  node:project) (cd "$path" && pnpm run dev 2>/dev/null || pnpm start) ;;
  python:project) (cd "$path" && uv run python -m "${name//-/_}") ;;
  rust:project) (cd "$path" && cargo run) ;;
  go:kata) (cd "$path" && go test ./... -v) ;;
  go:project) (cd "$path" && go run .) ;;
  esac
  ;;

watch)
  case "$lang:$kind" in
  node:kata) (cd "$path" && node --test --watch) ;;
  node:project) (cd "$path" && pnpm run dev 2>/dev/null || pnpm start) ;;
  python:kata) (cd "$path" && find . -name '*.py' | entr -c uv run pytest -q) ;;
  python:project) (cd "$path" && find . -name '*.py' | entr -c uv run pytest -q) ;;
  rust:kata) (cd "$ROOT/rust" && cargo watch -q -x "test -p katas $name -- --nocapture") ;;
  rust:project) (cd "$path" && cargo watch -q -x run) ;;
  go:kata) (cd "$path" && find . -name '*.go' | entr -c go test ./...) ;;
  go:project) (cd "$path" && find . -name '*.go' | entr -c go run .) ;;
  esac
  ;;

*)
  echo "unknown action: $action" >&2
  exit 1
  ;;
esac
