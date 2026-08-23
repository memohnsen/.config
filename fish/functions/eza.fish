function eza --description 'eza with the shared black/vivid file palette' --wraps eza
    # Keep this in an autoloaded function so already-running Fish sessions pick
    # it up on their next eza invocation without needing to source config.fish.
    set -lx EZA_COLORS 'di=38;5;75:ex=38;5;149:ln=38;5;80:or=38;5;203:pi=38;5;215:so=38;5;177:bd=38;5;203:cd=38;5;203:sc=38;5;149:bu=38;5;221:do=38;5;80:co=38;5;203:im=38;5;177:vi=38;5;177:mu=38;5;177:lo=38;5;177:cr=38;5;203:tm=38;5;243:cm=38;5;215:*.zig=38;5;149:*.zon=38;5;221:*.toml=38;5;177:*.json=38;5;221:*.md=38;5;80:*.org=38;5;80'
    command eza $argv
end
