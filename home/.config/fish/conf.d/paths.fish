# User paths (use $HOME for portability)
fish_add_path --global --path "$HOME/.local/bin"
fish_add_path --global --path "$HOME/bin"
fish_add_path --global --path "$HOME/go/bin"
fish_add_path --global --path "$HOME/.opencode/bin"
fish_add_path --global --path "$HOME/.cargo/bin"

# Dotfiles helper on PATH (repo may live in either place)
if test -x "$HOME/.dotfiles/dot"
    fish_add_path --global --path "$HOME/.dotfiles"
else if test -x "$HOME/workspace/personal/dot/dot"
    fish_add_path --global --path "$HOME/workspace/personal/dot"
end

# Omarchy tools
if test -d "$HOME/.local/share/omarchy/bin"
    fish_add_path --global --path "$HOME/.local/share/omarchy/bin"
end
