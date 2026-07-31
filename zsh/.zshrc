# === zinit plugin manager ===
ZINIT_HOME="${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

# Download zinit if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
  mkdir -p "$(dirname "$ZINIT_HOME")"
  git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi

source "$ZINIT_HOME/zinit.zsh"

# Plugins (turbo-loaded in the background after the first prompt).
# Order matters: completions in fpath -> compinit -> fzf-tab -> syntax-highlighting
# -> autosuggestions (last). fzf-tab must load after compinit but before the
# widget-wrapping plugins (fast-syntax-highlighting, zsh-autosuggestions).
zinit wait lucid for \
  blockf atpull'zinit creinstall -q .' \
    zsh-users/zsh-completions \
  atinit"ZINIT[COMPINIT_OPTS]=-C; zpcompinit; zpcdreplay" \
    Aloxaf/fzf-tab \
  zdharma-continuum/fast-syntax-highlighting \
  atload"!_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_find_no_dups

# Keybindings
bindkey -e
bindkey '^p' history-beginning-search-backward
bindkey '^n' history-beginning-search-forward

# Completion styling
if command -v vivid >/dev/null; then
  export LS_COLORS="$(vivid generate catppuccin-macchiato)"
fi
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
# Disable zsh's built-in menu so fzf-tab can take over
zstyle ':completion:*' menu no
# fzf-tab: preview directory contents when completing `cd`
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons=always $realpath'

alias ls="eza"
alias ll="eza -la"
alias cat="bat"

# Shell integrations
command -v fzf >/dev/null && eval "$(fzf --zsh)"

# Guarded so a machine missing any of these (e.g. a fresh Linux/WSL box)
# still gets a working interactive shell instead of `command not found`.
command -v fnm      >/dev/null && eval "$(fnm env --use-on-cd)"
command -v starship >/dev/null && eval "$(starship init zsh)"
# zoxide must be initialized at the very end of the config
command -v zoxide   >/dev/null && eval "$(zoxide init --cmd cd zsh)"
