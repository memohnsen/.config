# ~/.config/zsh/prompt.zsh

# Prevent Python virtualenv from polluting the prompt
export VIRTUAL_ENV_DISABLE_PROMPT=1

export FUNCNEST=100

if [[ -t 0 && -t 1 && "$TERM" != dumb ]] && command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
fi
