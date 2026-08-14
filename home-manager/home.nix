{ pkgs, ... }:

{
  home.username = "maddisenmohnsen";
  home.homeDirectory = "/Users/maddisenmohnsen";

  # This controls Home Manager compatibility defaults, not package versions.
  # Leave it unchanged when updating inputs unless the release notes say otherwise.
  home.stateVersion = "26.05";

  # Safety boundary: existing Fish/Git dotfiles, Homebrew applications,
  # macOS services, and project-specific toolchains remain untouched.
  programs.home-manager.enable = true;

  # General-purpose user tools belong here. Language toolchains, databases,
  # and project build dependencies remain in each repository's flake.
  home.packages = with pkgs; [
    aspell
    bat
    btop
    cloc
    claude-code
    coreutils
    discount
    direnv
    docker
    docker-compose
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
    neovim
    opencode
    pandoc
    ripgrep
    sentry-cli
    shellcheck
    starship
    tesseract
    tree-sitter
    uv
    zellij
    zoxide
  ];
}
