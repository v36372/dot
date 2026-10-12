# Public Exa MCP endpoint used by the pi-web-tools package.
set -gx PI_WEB_TOOLS_EXA_ENDPOINT https://mcp.exa.ai/mcp
# Disable greeting
set fish_greeting

# Core editor settings
set -gx EDITOR nvim
set -gx VISUAL nvim
set -gx OMARCHY_PATH /usr/share/omarchy
set -gx SUDO_EDITOR nvim
set -gx MANPAGER 'nvim +Man!'

# Prefer native Apple Silicon Homebrew when present (no-op on Linux).
if test -d /opt/homebrew/bin
    fish_add_path --global --move --path /opt/homebrew/bin
end

# Ensure user-local bins are first (common on Linux + custom installs)
fish_add_path --global --move --path "$HOME/.local/bin"

# Added by LM Studio CLI (lms)
set -gx PATH $PATH $HOME/.lmstudio/bin
# End of LM Studio CLI section

set -gx PATH $PATH $HOME/.bend/bin



# opencode
fish_add_path /Users/v36372/.opencode/bin
