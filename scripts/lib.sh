#!/usr/bin/env bash
#
# Shared helpers for the kata-gym scripts.
#
# This file is meant to be sourced, not executed:
#   source "$ROOT/scripts/lib.sh"
# The sourcing script must define ROOT (absolute path to the repository root).

# Supported values.
KATA_LANGUAGES=(node python rust go)
KATA_KINDS=(kata project)

# --- validation ----------------------------------------------------------

# is_supported_lang <value>
is_supported_lang() {
  local value
  for value in "${KATA_LANGUAGES[@]}"; do
    [ "$value" = "$1" ] && return 0
  done
  return 1
}

# is_supported_kind <value>
is_supported_kind() {
  local value
  for value in "${KATA_KINDS[@]}"; do
    [ "$value" = "$1" ] && return 0
  done
  return 1
}

# is_rust_kata <lang> <kind> — Rust katas are files in a shared crate, not directories.
is_rust_kata() { [ "$1:$2" = "rust:kata" ]; }

# --- locations -----------------------------------------------------------

# relative_base <lang> <kind> — item directory relative to ROOT.
relative_base() {
  case "$1:$2" in
  node:kata) printf '%s\n' "node/katas" ;;
  node:project) printf '%s\n' "node/projects" ;;
  python:kata) printf '%s\n' "python/katas" ;;
  python:project) printf '%s\n' "python/projects" ;;
  rust:kata) printf '%s\n' "rust/katas/src" ;;
  rust:project) printf '%s\n' "rust/projects" ;;
  go:kata) printf '%s\n' "go/katas" ;;
  go:project) printf '%s\n' "go/projects" ;;
  *) return 1 ;;
  esac
}

# item_base <lang> <kind> — absolute item directory.
item_base() {
  local rel
  rel="$(relative_base "$1" "$2")" || return 1
  printf '%s\n' "$ROOT/$rel"
}

# item_names <lang> <kind> — sorted item names, one per line.
# Rust katas are files, so the .rs suffix is stripped.
item_names() {
  local base
  base="$(item_base "$1" "$2")" || return 1
  [ -d "$base" ] || return 0
  if is_rust_kata "$1" "$2"; then
    find "$base" -maxdepth 1 -name 'lc_*.rs' -printf '%f\n' | sed 's/\.rs$//' | sort
  else
    find "$base" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort
  fi
}

# item_path <lang> <kind> <name> — absolute path of a single item.
item_path() {
  local base
  base="$(item_base "$1" "$2")" || return 1
  if is_rust_kata "$1" "$2"; then
    printf '%s\n' "$base/$3.rs"
  else
    printf '%s\n' "$base/$3"
  fi
}

# item_name <path> — item name derived from a path.
item_name() {
  local name
  name="$(basename "$1")"
  case "$name" in
  *.rs) name="${name%.rs}" ;;
  esac
  printf '%s\n' "$name"
}

# find_item_by_id <lang> <kind> <id> — first item matching an id, or nothing.
#
# Directory names follow the language convention, so an id is accepted in any
# spelling: `weather-cli` and `weather_cli` both find rust/projects/weather_cli.
find_item_by_id() {
  local lang="$1" kind="$2" id="$3"
  local base kebab snake pattern found
  local -a patterns

  base="$(item_base "$lang" "$kind")" || return 1
  [ -d "$base" ] || return 1

  kebab="${id//_/-}"
  snake="${id//-/_}"

  if [ "$kind" = "kata" ]; then
    case "$lang" in
    python | rust) patterns=("lc_${snake}_*") ;;
    *) patterns=("lc-${kebab}-*") ;;
    esac
  else
    patterns=("*${id}*" "*${kebab}*" "*${snake}*")
  fi

  for pattern in "${patterns[@]}"; do
    found="$(find "$base" -mindepth 1 -maxdepth 1 -name "$pattern" -print -quit)"
    if [ -n "$found" ]; then
      printf '%s\n' "$found"
      return 0
    fi
  done

  return 1
}

# --- interaction ---------------------------------------------------------

# choose_value <preselected> <label> <value...>
# Uses the preselected value when given, otherwise asks with gum.
choose_value() {
  local preset="$1" label="$2" value candidate
  shift 2
  if [ -n "$preset" ]; then
    value="$preset"
  elif ! value="$(gum choose --header "$label:" "$@")"; then
    return 130
  fi
  for candidate in "$@"; do
    if [ "$candidate" = "$value" ]; then
      printf '%s\n' "$value"
      return 0
    fi
  done
  printf 'invalid %s: %s (expected one of: %s)\n' "$label" "$value" "$*" >&2
  return 1
}

# current_path — path of the current selection, empty when there is none.
current_path() {
  [ -f "$ROOT/.current" ] || return 0
  cut -f4 "$ROOT/.current"
}
