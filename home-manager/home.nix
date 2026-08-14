{ pkgs, ... }:

let
  asc-cli = pkgs.callPackage ./packages/asc.nix { };
  codex-acp = pkgs.callPackage ./packages/codex-acp.nix { };
  meetcal-cli = pkgs.callPackage ./packages/meetcal.nix { };
  toml-grammar = pkgs.tree-sitter-grammars.tree-sitter-toml;
in
{
  home.username = "maddisenmohnsen";
  home.homeDirectory = "/Users/maddisenmohnsen";

  # This controls Home Manager compatibility defaults, not package versions.
  # Leave it unchanged when updating inputs unless the release notes say otherwise.
  home.stateVersion = "26.05";

  # Safety boundary: existing Fish/Git dotfiles, Homebrew applications,
  # macOS services, and project-specific toolchains remain untouched.
  programs.home-manager.enable = true;

  # General-purpose tools and editor-wide runtimes belong here. Repositories
  # still pin project-specific toolchains and build dependencies in their flakes.
  home.packages = with pkgs; [
    asc-cli
    aspell
    bat
    btop
    bun
    cloc
    claude-code
    codex
    codex-acp
    cargo-insta
    cargo-make
    coreutils
    discount
    direnv
    docker
    docker-compose
    dockfmt
    eas-cli
    emacs-lsp-booster
    eza
    fd
    fish
    fzf
    gh
    git
    git-filter-repo
    git-lfs
    gnugrep
    gnused
    gnutar
    hyperfine
    jq
    just
    maestro
    meetcal-cli
    neovim
    nodejs_24
    nixfmt
    opencode
    pandoc
    prettier
    postgresql_18
    ripgrep
    sentry-cli
    shellcheck
    shfmt
    starship
    tailwindcss-language-server
    tesseract
    tree-sitter
    typescript
    typescript-language-server
    uv
    vscode-langservers-extracted
    zellij
    zoxide
  ];

  # Doom already loads grammars from this directory. Let Home Manager supply
  # TOML alongside Doom's Zig grammar so GUI Emacs never needs an ad-hoc build.
  home.file.".config/emacs/.local/etc/tree-sitter/libtree-sitter-toml.dylib".source =
    "${toml-grammar}/parser";
}
