# Brewfile — shared, cross-platform formulae these dotfiles depend on.
# Install everything with:  brew bundle --file ~/dotfiles/Brewfile
#
# Works on macOS and Linux/WSL (Linuxbrew). GUI apps are casks, which
# Linuxbrew does not support, so they live in Brewfile.macos and are
# loaded only when running on macOS (see the bottom of this file).

# Dotfiles management
brew "stow"       # symlink farm manager for the stow packages

# Shell (zsh config)
brew "fnm"        # fast node version manager
brew "starship"   # cross-shell prompt
brew "zoxide"     # smarter cd
brew "eza"        # modern ls replacement
brew "bat"        # cat with syntax highlighting
brew "fzf"        # fuzzy finder + zsh keybindings/completion
brew "vivid"      # LS_COLORS generator (completion + eza colors)

# Terminal multiplexers
brew "tmux"
brew "herdr"

# macOS-only GUI apps (casks). Resolve the path relative to THIS file
# (__FILE__), not the shell's cwd — brew bundle does not chdir to the
# Brewfile's directory, so a bare "Brewfile.macos" would break whenever
# `brew bundle` is run from anywhere other than ~/dotfiles.
instance_eval(File.read(File.expand_path("Brewfile.macos", File.dirname(__FILE__)))) if OS.mac?
