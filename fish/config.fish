set -g fish_greeting ""

# Drop paths injected by a legacy nix-darwin /etc/zshenv before adding the
# Homebrew and Mise environments below.
set -l clean_path
for entry in $PATH
    if not string match -q '/nix/*' $entry; and not string match -q "$HOME/.nix-profile/*" $entry; and not string match -q '/run/current-system/*' $entry
        set --append clean_path $entry
    end
end
set --global --export PATH $clean_path
set --erase NIX_PROFILES NIX_PATH NIX_SSL_CERT_FILE

if status is-interactive
    # Commands to run in interactive sessions can go here
	abbr -a .. cd ..
	abbr -a n nvim
	abbr -a ga git add .
	abbr -a gs git status
	abbr -a gc git commit
	abbr -a ls eza --icons
	abbr -a ll eza -lh --icons --git
	abbr -a la eza -lah --icons --git
	abbr -a tree eza --tree --icons
	abbr -a cat bat
	abbr -a zls zellij ls
	abbr -a zda zellij da
	abbr -a zka zellij ka
	abbr -a za zellij a
	abbr -a jr mise run run
	abbr -a jb mise run build
	abbr -a jt mise run test
	abbr -a jl mise run lint
	abbr -a top btop
	abbr -a co codex
	abbr -a cl clear
end

# Prefer Home Manager packages while retaining Homebrew as a fallback.
fish_add_path --append /opt/homebrew/bin
fish_add_path ~/.local/bin
set -gx EDITOR nvim

fish_vi_key_bindings
mise activate fish | source
zoxide init fish | source

if command -q direnv
	direnv hook fish | source
end
