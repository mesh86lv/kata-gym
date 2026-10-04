{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    # node
    nodejs_22
    pnpm
    gum

    # python
    python312
    entr
    uv

    # rust
    rustc
    cargo
    cargo-watch
    rust-analyzer

    # go
    go
    gopls
    gotools

    # task runner
    just
  ];

  shellHook = ''
    echo "kata-gym: dev shell ready (node $(node -v), python $(python3 --version), rustc $(rustc --version), go $(go version))"
  '';
}
