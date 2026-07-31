set -g fish_greeting ""

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
end

fish_add_path /opt/homebrew/bin
fish_add_path ~/.local/bin
set -gx EDITOR nvim

fish_vi_key_bindings
zoxide init fish | source

# ZVM
set -gx ZVM_INSTALL "$HOME/.zvm/self"
set -gx PATH $PATH "$HOME/.zvm/bin"
set -gx PATH $PATH "$ZVM_INSTALL/"
