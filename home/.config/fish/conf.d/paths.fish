# User paths (use $HOME for portability)
fish_add_path --global --path "$HOME/.local/bin"
fish_add_path --global --path "$HOME/bin"
fish_add_path --global --path "$HOME/go/bin"
fish_add_path --global --path "$HOME/.opencode/bin"
fish_add_path --global --path "$HOME/.cargo/bin"
fish_add_path --global --path "$HOME/.bun/bin"
fish_add_path --global --path "$HOME/.foundry/bin"
fish_add_path --global --path "$HOME/.gvm/bin"
fish_add_path --global --path "$HOME/.orbstack/bin"

# Optional legacy Homebrew tools still installed on this Mac.
for path in /usr/local/opt/libpq/bin /usr/local/opt/python@3.10/bin
    if test -d "$path"
        fish_add_path --global --path "$path"
    end
end

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
