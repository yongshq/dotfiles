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

# Oh My Zsh git aliases (gst, gco, gcb, gp, gd, glol, ...) pulled in as bare
# snippets — no OMZ framework install. The lib must come first: the plugin's
# branch-aware aliases call `git_current_branch`, which lives in lib/git.zsh.
zinit wait lucid for \
  OMZL::git.zsh \
  OMZP::git

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

# Discard every uncommitted change in the current repo: tracked files (modified
# or staged) are restored to HEAD, untracked files and directories are deleted.
# Ignored files (.env, node_modules, build output) are KEPT unless -x is given.
# Shows exactly what will be lost and asks first; -y skips the prompt.
# Irreversible -- uncommitted work cannot be recovered from the reflog.
# A confirming wrapper around the OMZ git plugin's silent `gwipe`/`gpristine`.
gnuke() {
  emulate -L zsh
  local nuke_ignored=0 assume_yes=0
  while (( $# )); do
    case $1 in
      -x|--ignored) nuke_ignored=1 ;;
      -y|--yes)     assume_yes=1 ;;
      -h|--help)    print "usage: gnuke [-x|--ignored] [-y|--yes]"; return 0 ;;
      *) print -u2 "gnuke: unknown option: $1"; return 2 ;;
    esac
    shift
  done

  git rev-parse --is-inside-work-tree &>/dev/null || {
    print -u2 "gnuke: not inside a git work tree"; return 1
  }

  local -a dry=(-nd); (( nuke_ignored )) && dry+=(-x)
  local tracked untracked
  tracked=$(git status --porcelain --untracked-files=no)
  untracked=$(git clean $dry | sed 's/^Would remove /  /')

  [[ -z $tracked && -z $untracked ]] && { print "gnuke: already clean"; return 0 }

  print "About to discard, in $(git rev-parse --show-toplevel):"
  [[ -n $tracked   ]] && { print "\n  restore to HEAD:"; print -r -- "$tracked" | sed 's/^/  /' }
  [[ -n $untracked ]] && { print "\n  delete:"; print -r -- "$untracked" }
  (( nuke_ignored )) && print "\n  (-x: ignored files included)"

  if (( ! assume_yes )); then
    local reply
    read -r "reply?
Proceed? [y/N] "
    [[ $reply == [yY] ]] || { print "aborted"; return 1 }
  fi

  local -a clean=(--force -d); (( nuke_ignored )) && clean+=(-x)
  git reset --hard --quiet && git clean $clean
}

# Shell integrations
command -v fzf >/dev/null && eval "$(fzf --zsh)"

# Guarded so a machine missing any of these (e.g. a fresh Linux/WSL box)
# still gets a working interactive shell instead of `command not found`.
command -v fnm      >/dev/null && eval "$(fnm env --use-on-cd)"
command -v starship >/dev/null && eval "$(starship init zsh)"
# zoxide must be initialized at the very end of the config
command -v zoxide   >/dev/null && eval "$(zoxide init --cmd cd zsh)"
