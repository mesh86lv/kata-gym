# Unified task runner for kata-gym.
# Run `just` to list all recipes.

# --- default ------------------------------------------------------------

default:
    @just status 2>/dev/null || true
    @just --list

# --- interactive (pick → state → action) --------------------------------

# Select the current item (language → kata/project → item).
# You can preselect: just pick go kata
pick lang='' kind='':
    @bash scripts/pick.sh {{lang}} {{kind}}

# Run the current item (for a kata == tests with output).
run:
    @bash scripts/action.sh run

# Run the tests of the current item.
test:
    @bash scripts/action.sh test

# Watch the current item and re-run on change.
watch:
    @bash scripts/action.sh watch

# Open the current item in $EDITOR.
open:
    @bash scripts/action.sh open

# Show what is currently selected.
status:
    @bash scripts/action.sh status

# Forget the current selection.
clear:
    @bash scripts/action.sh clear

# Run without pick: just test-one rust kata 0002
test-one lang kind id:
    @bash scripts/action.sh --one {{lang}} {{kind}} {{id}} test

# Run without pick: just run-one go project weather-cli
run-one lang kind id:
    @bash scripts/action.sh --one {{lang}} {{kind}} {{id}} run

# --- catalog -------------------------------------------------------------

# List katas and projects. No arguments lists every language.
# Examples: just list | just list go | just list go kata
list lang='' kind='':
    @bash scripts/list.sh {{lang}} {{kind}}

# Delete a kata or project. Without arguments the picker asks for everything.
# Examples: just delete
#           just delete rust kata 0002
#           just delete rust kata 0002 yes    (skip the confirmation)
delete lang='' kind='' id='' yes='':
    @bash scripts/delete.sh {{lang}} {{kind}} {{id}} {{yes}}

# --- tests (all at once, for CI) -----------------------------------------

test-node:
    cd node && pnpm -r test

test-python:
    cd python && uv run pytest -q || [ $? -eq 5 ]

test-rust: rust-sync
    cd rust && cargo test --workspace

test-go:
    cd go && pkgs="$(go list ./...)" && { [ -z "$pkgs" ] || go test $pkgs; }

test-all: test-node test-python test-rust test-go

# --- setup ---------------------------------------------------------------

install-node:
    cd node && pnpm install

install-python:
    cd python && uv sync

# Reconcile rust/Cargo.toml workspace members with the directories on disk.
# A listed-but-missing member breaks every cargo command in the workspace.
rust-sync:
    @bash scripts/rust-sync.sh

install-rust: rust-sync
    cd rust && cargo fetch

install-go:
    cd go && go mod download

install-all: install-node install-python install-rust install-go

# --- scaffolding ---------------------------------------------------------

# Usage: just new-kata node 0002 add-two-numbers
new-kata lang id name:
    @bash scripts/new-kata.sh {{lang}} {{id}} {{name}}

# Usage: just new-project <lang> <name>
new-project lang name:
    @bash scripts/new-project.sh {{lang}} {{name}}

# --- formatting ----------------------------------------------------------

fmt-rust:
    cd rust && cargo fmt --all

fmt-node:
    cd node && pnpm -r exec -- true # plug in prettier/biome here if added

fmt-go:
    cd go && gofmt -w .

# --- prune ---------------------------------------------------------------

# Delete whole languages (directories + templates).
# Example: just prune python rust
prune first *rest:
    #!/usr/bin/env bash
    set -euo pipefail
    for lang in {{first}} {{rest}}; do
        case "$lang" in
            node)   rm -rf node/   scripts/templates/katas-node   scripts/templates/project-node ;;
            python) rm -rf python/ scripts/templates/katas-python scripts/templates/project-python ;;
            rust)   rm -rf rust/   scripts/templates/katas-rust   scripts/templates/project-rust ;;
            go)     rm -rf go/     scripts/templates/katas-go     scripts/templates/project-go ;;
            *) echo "unknown lang: $lang" >&2; exit 1 ;;
        esac
        echo "removed $lang"
    done
