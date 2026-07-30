# dotfiles

Personal macOS dotfiles, managed with [GNU Stow](https://www.gnu.org/software/stow/).

Each top-level directory is a **stow package** whose internal layout mirrors
`$HOME`. Running `stow <package>` symlinks its contents into the right place —
e.g. `zsh/.zshrc` → `~/.zshrc`, `tmux/.config/tmux/tmux.conf` →
`~/.config/tmux/tmux.conf`.

## What's inside

| Package  | Links to                     | What it is |
|----------|------------------------------|------------|
| `zsh`    | `~/.zshrc`                   | Shell config: `fnm`, `starship`, `zoxide` (with `cd`), `eza`/`bat` aliases |
| `tmux`   | `~/.config/tmux/`            | tmux config — sensible defaults, Ghostty truecolor, bell-based alerts |
| `herdr`   | `~/.config/herdr/`          | [herdr](https://herdr.dev) agent multiplexer config (only `config.toml` is tracked) |
| `ghostty` | `~/.config/ghostty/config`  | [Ghostty](https://ghostty.org) terminal config (only `config`; `auto/` is left untouched) |
| `claude`  | `~/.claude/`                | Claude Code statusline script |

## Prerequisites

[Homebrew](https://brew.sh) and the tools referenced by the configs:

```sh
brew install stow fnm starship zoxide eza bat jq tmux herdr
```

## Install

```sh
git clone git@github.com:yongshq/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Symlink everything...
stow zsh tmux herdr ghostty claude

# ...or pick individual packages
stow zsh
```

Stow refuses to overwrite existing real files — back up or remove any
conflicting `~/.zshrc` etc. first, or re-run with `--adopt` to pull existing
files into the repo.

## Updating a package

Edit files inside the package (they're symlinked, so edits take effect live),
then commit. To restow after adding new files:

```sh
cd ~/dotfiles && stow -R <package>   # -R = restow
```

## Removing a package

```sh
cd ~/dotfiles && stow -D <package>   # -D = delete the symlinks
```

## Notes

- **tmux** and **herdr** are both terminal multiplexers kept side by side for
  evaluation. Both use the `Ctrl-b` prefix — don't nest one inside the other.
- **herdr** writes logs, sockets, and session state into `~/.config/herdr/`;
  a `.gitignore` in that package keeps everything but `config.toml` untracked.
