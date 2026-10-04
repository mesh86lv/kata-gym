#!/usr/bin/env bash
#
# Scaffold a new kata from the templates in scripts/templates/.
#
# Usage:
#   ./scripts/new-kata.sh <node|python|rust|go> <id> <slug-name>
#
# Examples:
#   ./scripts/new-kata.sh node   0002 add-two-numbers
#   ./scripts/new-kata.sh python 0002 add-two-numbers
#   ./scripts/new-kata.sh rust   0002 add-two-numbers
#   ./scripts/new-kata.sh go     0002 add-two-numbers

set -euo pipefail

LANG="${1:?usage: new-kata.sh <node|python|rust|go> <id> <name>}"
ID="${2:?missing id, e.g. 0002}"
NAME_RAW="${3:?missing name, e.g. add-two-numbers}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "$LANG" in
node)
  NAME_KEBAB="$(echo "$NAME_RAW" | tr '_' '-')"
  DEST="$ROOT/node/katas/lc-${ID}-${NAME_KEBAB}"
  SRC="$ROOT/scripts/templates/katas-node"
  [ -d "$DEST" ] && {
    echo "already exists: $DEST" >&2
    exit 1
  }
  mkdir -p "$(dirname "$DEST")"
  cp -r "$SRC" "$DEST"
  find "$DEST" -type f -exec sed -i "s/__ID__/${ID}/g; s/__NAME__/${NAME_KEBAB}/g" {} +
  echo "created $DEST"
  ;;

python)
  NAME_SNAKE="$(echo "$NAME_RAW" | tr '-' '_')"
  DEST="$ROOT/python/katas/lc_${ID}_${NAME_SNAKE}"
  SRC="$ROOT/scripts/templates/katas-python"
  [ -d "$DEST" ] && {
    echo "already exists: $DEST" >&2
    exit 1
  }
  mkdir -p "$(dirname "$DEST")"
  cp -r "$SRC" "$DEST"
  # Unique module names per kata: with a shared solution.py / test_solution.py,
  # collecting the whole suite at once fails with "import file mismatch" and,
  # even when it does not fail, `from solution import solve` resolves through
  # sys.modules and can silently pick a sibling kata's solution.
  mv "$DEST/solution.py" "$DEST/${NAME_SNAKE}.py"
  mv "$DEST/test_solution.py" "$DEST/test_${NAME_SNAKE}.py"
  sed -i "s/^from solution import/from ${NAME_SNAKE} import/" "$DEST/test_${NAME_SNAKE}.py"
  find "$DEST" -type f -exec sed -i "s/__ID__/${ID}/g; s/__NAME__/${NAME_SNAKE}/g" {} +
  echo "created $DEST"
  ;;

rust)
  NAME_SNAKE="$(echo "$NAME_RAW" | tr '-' '_')"
  MODULE="lc_${ID}_${NAME_SNAKE}"
  DEST="$ROOT/rust/katas/src/${MODULE}.rs"
  LIB="$ROOT/rust/katas/src/lib.rs"
  [ -f "$DEST" ] && {
    echo "already exists: $DEST" >&2
    exit 1
  }
  mkdir -p "$(dirname "$LIB")"
  [ -f "$LIB" ] || cp "$ROOT/scripts/templates/katas-rust/lib.rs" "$LIB"
  sed "s/__NAME__/${NAME_SNAKE}/g" "$ROOT/scripts/templates/katas-rust/rust-kata.rs" >"$DEST"
  MARKER="// @kata-modules"
  if ! grep -q "^pub mod ${MODULE};" "$LIB" 2>/dev/null; then
    if ! grep -qF "$MARKER" "$LIB"; then
      echo "marker '$MARKER' not found in $LIB" >&2
      exit 1
    fi
    awk -v m="$MARKER" -v ins="pub mod ${MODULE};" '
      !done && index($0, m) { print ins; done = 1 }
      { print }
    ' "$LIB" > "$LIB.tmp" && mv "$LIB.tmp" "$LIB"
  fi
  echo "created $DEST (registered in $LIB)"
  ;;

go)
  NAME_KEBAB="$(echo "$NAME_RAW" | tr '_' '-')"
  DEST="$ROOT/go/katas/lc-${ID}-${NAME_KEBAB}"
  SRC="$ROOT/scripts/templates/katas-go"
  [ -d "$DEST" ] && {
    echo "already exists: $DEST" >&2
    exit 1
  }
  mkdir -p "$DEST"
  cp -r "$SRC"/. "$DEST"/
  find "$DEST" -type f -exec sed -i "s/__ID__/${ID}/g; s/__NAME__/${NAME_KEBAB}/g" {} +
  echo "created $DEST"
  ;;
*)
  echo "unknown lang: $LANG (expected node|python|rust|go)" >&2
  exit 1
  ;;
esac
