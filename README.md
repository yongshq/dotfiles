# dotfiles

Personal dotfiles (primarily macOS; Linux/WSL supported — see
[Linux / WSL](#linux--wsl)), managed with
[GNU Stow](https://www.gnu.org/software/stow/).

Each top-level directory is a **stow package** whose internal layout mirrors
`$HOME`. Running `stow <package>` symlinks its contents into the right place —
e.g. `zsh/.zshrc` → `~/.zshrc`, `tmux/.config/tmux/tmux.conf` →
`~/.config/tmux/tmux.conf`.

[`AGENTS.md`](./AGENTS.md) at the repo root is the **agent-agnostic** source of
truth for coding-agent workflow rules (commit discipline, git worktree
conventions). Each agent's own config file just references it, so the same rules
apply everywhere — e.g. `claude/.claude/CLAUDE.md` is a real file that imports it
with Claude Code's `@~/dotfiles/AGENTS.md` syntax (this assumes the repo is
cloned to `~/dotfiles`, as below). To onboard another agent (Codex, Cursor,
Aider, …), add a package whose config file references `AGENTS.md` the same way —
an `@`-import, an `include`, or a symlink, whatever that agent supports.

## What's inside

| Package  | Links to                     | What it is |
|----------|------------------------------|------------|
| `zsh`    | `~/.zshrc`                   | Shell config: `fnm`, `starship`, `zoxide` (with `cd`), `eza`/`bat` aliases |
| `tmux`   | `~/.config/tmux/`            | tmux config — sensible defaults, Ghostty truecolor, bell-based alerts |
| `herdr`   | `~/.config/herdr/`          | [herdr](https://herdr.dev) agent multiplexer config (only `config.toml` is tracked) |
| `ghostty` | `~/.config/ghostty/config`  | [Ghostty](https://ghostty.org) terminal config (only `config`; `auto/` is left untouched) |
| `claude`  | `~/.claude/`                | Claude Code config: `CLAUDE.md` (imports root `AGENTS.md`, the shared workflow rules, via `@`), `settings.json`, statusline script (individual files only; runtime state and `settings.local.json` stay untracked) |

## Prerequisites

[Homebrew](https://brew.sh). Every CLI tool and app the configs reference is
declared in the [`Brewfile`](./Brewfile) and installed during setup below.

## Install

```sh
git clone git@github.com:yongshq/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Install the tools the configs depend on (reads ./Brewfile)
brew bundle

# Symlink everything...
stow zsh tmux herdr ghostty claude

# ...or pick individual packages
stow zsh
```

Stow refuses to overwrite existing real files — back up or remove any
conflicting `~/.zshrc` etc. first, or re-run with `--adopt` to pull existing
files into the repo.

## Linux / WSL

These configs run on Linux and WSL too, with a few macOS-only pieces that are
handled or safely ignored:

- **Homebrew casks** — the [`Brewfile`](./Brewfile) holds only cross-platform
  formulae and loads the GUI casks from [`Brewfile.macos`](./Brewfile.macos)
  *only when `OS.mac?`*. So `brew bundle` runs cleanly on Linuxbrew, which has
  no cask support. Install the GUI apps (Ghostty, Claude Code) another way
  there — your distro's package manager or, for Claude Code, npm.
- **Ghostty** — inside WSL you typically use **Windows Terminal** (or WSLg) as
  the emulator rather than Ghostty, so `ghostty/` goes unused. The
  `macos-option-as-alt` line is a no-op off macOS; on Linux/Windows the `Alt`
  key already sends a clean chord, so herdr's `alt+h/j/k/l` pane switching works
  with no extra config.
- **Everything else** — `zsh`, `tmux`, `herdr`, and `claude` are portable and
  stow the same way. `.zshrc` has no hardcoded Homebrew paths and guards every
  integration behind `command -v`, so missing tools degrade gracefully.

Install is otherwise identical — `brew bundle` (or your distro's packages),
then `stow zsh tmux herdr claude` (skip `ghostty` if you're not running it).

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
