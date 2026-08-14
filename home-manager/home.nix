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
    cloc
    claude-code
    codex
    codex-acp
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
    maestro
    meetcal-cli
    neovim
    nixfmt
    opencode
    pandoc
    prettier
    ripgrep
    sentry-cli
    shellcheck
    shfmt
    starship
    tesseract
    tree-sitter
    zellij
    zoxide
  ];

  # Doom already loads grammars from this directory. Let Home Manager supply
  # TOML alongside Doom's Zig grammar so GUI Emacs never needs an ad-hoc build.
  home.file.".config/emacs/.local/etc/tree-sitter/libtree-sitter-toml.dylib".source =
    "${toml-grammar}/parser";
}
