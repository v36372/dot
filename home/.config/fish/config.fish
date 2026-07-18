# Disable greeting
set fish_greeting

# Core editor settings
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx SUDO_EDITOR nvim
set -gx MANPAGER 'nvim +Man!'

# Prefer native Apple Silicon Homebrew tools over stale Intel Homebrew installs
fish_add_path --global --move --path /opt/homebrew/bin

# Ensure user-local fish data/bin are first (user-local install path)
fish_add_path --global --move --path "$HOME/.local/bin"
