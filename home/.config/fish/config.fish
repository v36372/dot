# Disable greeting
set fish_greeting

# Core editor settings
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx SUDO_EDITOR nvim
set -gx MANPAGER 'nvim +Man!'

# Prefer native Apple Silicon Homebrew when present (no-op on Linux).
if test -d /opt/homebrew/bin
    fish_add_path --global --move --path /opt/homebrew/bin
end

# Ensure user-local bins are first (common on Linux + custom installs)
fish_add_path --global --move --path "$HOME/.local/bin"

# Added by LM Studio CLI (lms)
set -gx PATH $PATH /home/v36372/.lmstudio/bin
# End of LM Studio CLI section

