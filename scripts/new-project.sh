#!/usr/bin/env bash
#
# Scaffold a new project from scripts/templates/project-<lang>/.
#
# Usage:
#   ./scripts/new-project.sh <node|python|rust|go> <name>
#
# Examples:
#   ./scripts/new-project.sh node   weather-cli
#   ./scripts/new-project.sh python telegram-bot
#   ./scripts/new-project.sh rust   json-parser
#   ./scripts/new-project.sh go     weather-cli

set -euo pipefail

LANG="${1:?usage: new-project.sh <node|python|rust|go> <name>}"
NAME_RAW="${2:?missing name, e.g. weather-cli}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

case "$LANG" in
node)
  NAME_KEBAB="$(echo "$NAME_RAW" | tr '_' '-')"
  DEST="$ROOT/node/projects/${NAME_KEBAB}"
  SRC="$ROOT/scripts/templates/project-node"
  [ -d "$DEST" ] && {
    echo "already exists: $DEST" >&2
    exit 1
  }
  mkdir -p "$(dirname "$DEST")"
  cp -r "$SRC" "$DEST"
  find "$DEST" -type f -exec sed -i "s/__NAME__/${NAME_KEBAB}/g" {} +
  echo "created $DEST"
  ;;

python)
  NAME_SNAKE="$(echo "$NAME_RAW" | tr '-' '_')"
  DEST="$ROOT/python/projects/${NAME_SNAKE}"
  SRC="$ROOT/scripts/templates/project-python"
  [ -d "$DEST" ] && {
    echo "already exists: $DEST" >&2
    exit 1
  }
  mkdir -p "$(dirname "$DEST")"
  cp -r "$SRC" "$DEST"
  # The template keeps the package in a dir literally named __NAME__; sed only
  # rewrites file contents, so rename the directory as well.
  while IFS= read -r placeholder; do
    mv "$placeholder" "$(dirname "$placeholder")/${NAME_SNAKE}"
  done < <(find "$DEST" -depth -type d -name '__NAME__')
  find "$DEST" -type f -exec sed -i "s/__NAME__/${NAME_SNAKE}/g" {} +
  echo "created $DEST"
  ;;

rust)
  NAME_SNAKE="$(echo "$NAME_RAW" | tr '-' '_')"
  DEST="$ROOT/rust/projects/${NAME_SNAKE}"
  SRC="$ROOT/scripts/templates/project-rust"

  [ -d "$DEST" ] && {
    echo "already exists: $DEST" >&2
    exit 1
  }

  mkdir -p "$ROOT/rust/projects"
  cp -r "$SRC" "$DEST"
  find "$DEST" -type f -exec sed -i "s/__NAME__/${NAME_SNAKE}/g" {} +
  rm -rf "$DEST/target"
  # A stale member breaks the whole Cargo workspace, so let the script reconcile it.
  bash "$ROOT/scripts/rust-sync.sh"
  echo "created $DEST"
  ;;

go)
  NAME_KEBAB="$(echo "$NAME_RAW" | tr '_' '-')"
  DEST="$ROOT/go/projects/${NAME_KEBAB}"
  SRC="$ROOT/scripts/templates/project-go"
  [ -d "$DEST" ] && {
    echo "already exists: $DEST" >&2
    exit 1
  }
  mkdir -p "$DEST"
  cp -r "$SRC"/. "$DEST"/
  find "$DEST" -type f -exec sed -i "s/__NAME__/${NAME_KEBAB}/g" {} +
  echo "created $DEST"
  ;;
*)
  echo "unknown lang: $LANG (expected node|python|rust|go)" >&2
  exit 1
  ;;
esac
