# === zinit plugin manager ===
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

# Download zinit if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "$ZINIT_HOME/zinit.zsh"

# Plugins (turbo-loaded in the background after the first prompt)
zinit wait lucid for \
  atload"_zsh_autosuggest_start; bindkey '^ ' autosuggest-accept; bindkey '^@' autosuggest-accept" zsh-users/zsh-autosuggestions \
  blockf atpull'zinit creinstall -q .' zsh-users/zsh-completions \
  atinit"zpcompinit; zpcdreplay" zdharma-continuum/fast-syntax-highlighting

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Cycle history with Ctrl+P / Ctrl+N
bindkey '^p' history-search-backward
bindkey '^n' history-search-forward

alias ls="eza"
alias ll="eza -la"
alias cat="bat"

eval "$(fnm env --use-on-cd)"
eval "$(starship init zsh)"
# zoxide must be initialized at the very end of the config
eval "$(zoxide init --cmd cd zsh)"
