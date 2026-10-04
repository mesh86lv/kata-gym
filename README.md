# kata-gym

A polyglot practice repo: algorithmic katas (LeetCode / CodeWars) and small
projects in Node, Python, Rust, and Go.

Every language has the same layout — `katas/` for exercises and `projects/`
for larger builds — and is driven by a single `justfile`.

## Quick start

```bash
direnv allow          # loads shell.nix through nix-direnv
just install-all      # pnpm install + uv sync + cargo fetch + go mod download
just test-all         # run the test suites of all four languages
```

The toolchain comes from `shell.nix` (Node 22, Python 3.12 + uv, Rust +
cargo-watch, Go + gopls, `just`, `gum`, `entr`). If you do not use Nix, install
those tools yourself; `go` must be 1.22 or newer.

## Daily workflow

`just pick` stores the current selection in `.current` and the other recipes
operate on it:

```bash
just pick             # choose language -> kata or project -> item
just pick go kata     # skip the prompts: language and kind preselected
just test             # run the tests of the current item
just run              # katas: tests with output; projects: start the app
just watch            # re-run on file changes
just open             # open the current item in $EDITOR
just list             # list every kata and project
just status           # show what is currently selected
just clear            # forget the current selection
```

Running `just` with no recipe prints the current selection and lists all
recipes. To skip the interactive picker and target one kata directly:

```bash
just test-one rust kata 0002
just test-one go kata 0002
just run-one go project weather-cli
```

Note that `just` passes surplus words to *other* recipes: in
`just new-project go weather-cli test`, `test` is not an argument of
`new-project` but a second recipe that will be run. Pass exactly the arguments
a recipe declares.

## List and delete

```bash
just list                  # every language, katas and projects
just list go                # only go
just list go kata           # only go katas
just delete                 # picker, then a confirmation prompt
just delete rust kata 0002  # by id
just delete rust kata 0002 yes   # skip the confirmation
```

`just list` marks the current selection with `*`. `just delete` removes the item
and keeps the repo consistent:

- a Rust kata is a single file, so its module file **and** the matching
  `pub mod ...;` line in `rust/katas/src/lib.rs` are removed;
- projects need no manual manifest edit — node and python use workspace globs,
  Go shares the single module, and Rust is reconciled by `rust-sync` (see above),
  which `just delete` runs for you;
- if the deleted item was the current selection, `.current` is cleared.

Deletion is irreversible. Run `just list` first if you are unsure about the id.

An id is accepted in either spelling: `weather-cli` and `weather_cli` both
resolve to `rust/projects/weather_cli`. Run `just list <lang> <kind>` whenever
the exact name is unclear — a failed lookup prints that hint too.

## Add a kata

```bash
just new-kata node   0002 add-two-numbers
just new-kata python 0002 add-two-numbers
just new-kata rust   0002 add-two-numbers
just new-kata go     0002 add-two-numbers
```

The script copies the matching template from `scripts/templates/` and applies
the naming convention of the language:

| Language | Location                                         | Naming                  |
| -------- | ------------------------------------------------ | ----------------------- |
| Node     | `node/katas/lc-0002-add-two-numbers/`            | kebab-case directory    |
| Python   | `python/katas/lc_0002_add_two_numbers/`          | snake_case directory    |
| Rust     | `rust/katas/src/lc_0002_add_two_numbers.rs`      | snake_case module       |
| Go       | `go/katas/lc-0002-add-two-numbers/`              | kebab-case directory    |

For Rust the file itself is a module of the single `katas` crate, so the script
also registers it in `rust/katas/src/lib.rs` by inserting `pub mod lc_…;` right
before the `// @kata-modules` marker. Keep that marker as the last line of the
file — the script refuses to run if it is missing.
For Python the solution and test modules are named after the kata slug
(`two_sum.py`, `test_two_sum.py`). A shared `solution.py` in every kata would
collide: collecting the whole suite at once fails with `import file mismatch`,
and even then `from solution import solve` resolves through `sys.modules` and
can silently pick a sibling kata's solution.


## Add a project

```bash
just new-project node   weather-cli
just new-project python weather-cli
just new-project rust   weather-cli
just new-project go     weather-cli
```

Node, Python, and Go projects need no manifest edit: node and python are
covered by their workspace globs, Go shares the single Go module. Rust is the
exception:
`rust/projects/*` are members of the Cargo workspace, and Cargo fails hard when
a listed member is missing, so `rust/Cargo.toml` is reconciled from disk by
`just rust-sync`. That recipe also runs automatically before `just test-rust`,
`just install-rust`, and after `just new-project rust` / `just delete`.

## Remove languages you do not use

If you only practise one language, drop the rest:

```bash
just prune python rust      # remove python/ and rust/
just prune go               # keep only go/
```

`just prune` deletes the language directory together with its kata and project
templates, and needs at least one language argument. It does not edit
`justfile` or `shell.nix`, so remember to remove the matching recipes and
packages there, or `just install-all` / `just test-all` will fail.

Doing it by hand is equivalent:

```bash
rm -rf python/ rust/ go/
```

> `just prune` is irreversible. Run it only after your work is committed.

## Structure

```
kata-gym/
├── shell.nix / .envrc     # toolchain versions via nix + direnv
├── justfile               # single entry point for all commands
├── scripts/               # kata/project generator + templates
├── node/                  # pnpm workspace: katas/*, projects/*
├── python/                # uv workspace: katas/*, projects/*
├── rust/                  # cargo workspace: katas (one crate of modules), projects/*
└── go/                    # one Go module: katas/* (packages), projects/* (package main)
```

## Progress tracker

| #   | Task    | Node | Python | Rust | Go  | Date       |
| --- | ------- | :--: | :----: | :--: | :-: | ---------- |
| 1   | Two Sum |  ✅  |   ✅   |  ✅  |  ✅ | 2026-09-11 |

## Cheat sheet

- Node: `node --test` runs the tests with no extra runner; `pnpm -r test` from `node/`.
- Python: `uv run pytest` from `python/`.
- Rust: `cargo test --workspace` from `rust/`; formatting with `cargo fmt --all`.
- Go: `go test ./...` from `go/`, `go run .` inside a project directory; formatting with `gofmt -w .`.

## Formatting

```bash
just fmt-node
just fmt-rust
just fmt-go
```

`fmt-node` is a placeholder until a formatter such as prettier or biome is
added.
