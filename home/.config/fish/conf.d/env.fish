# Omarchy path marker (used by omarchy-* tools)
set -gx OMARCHY_PATH "$HOME/.local/share/omarchy"

# Bat / prettier man pages when not using nvim manpager
set -gx BAT_THEME ansi
set -gx MANROFFOPT -c

# FZF defaults
set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border'

# Local env shims (mise/uv/etc installers sometimes drop these)
if test -f "$HOME/.local/bin/env.fish"
    source "$HOME/.local/bin/env.fish"
end

# Cargo (fish-native if present)
if test -f "$HOME/.cargo/env.fish"
    source "$HOME/.cargo/env.fish"
end
