# Packages

## Core
- fish (or use user-local `~/.local/bin/fish` temporarily)
- stow neovim tmux starship ripgrep fd fzf git lazygit eza bat zoxide mise

## Promote fish system-wide
See `install-fish-system.md`.

## Herdr local float popup
See `herdr-toggle-popup/README.md`.

```bash
cd packages/herdr-toggle-popup
go build -o bin/toggle-popup .
herdr plugin link "$PWD"
```
