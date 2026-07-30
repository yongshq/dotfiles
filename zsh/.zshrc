# === zinit plugin manager ===
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

# Download zinit if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "$ZINIT_HOME/zinit.zsh"

# Plugins (loaded fast, in the background after the first prompt)
zinit wait lucid for \
  zsh-users/zsh-autosuggestions \
  zsh-users/zsh-completions \
  zdharma-continuum/fast-syntax-highlighting

alias ls="eza"
alias ll="eza -la"
alias cat="bat"

eval "$(fnm env --use-on-cd)"
eval "$(starship init zsh)"
# zoxide must be initialized at the very end of the config
eval "$(zoxide init --cmd cd zsh)"
