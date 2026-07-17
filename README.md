# dot

Personal dotfiles for Linux (Omarchy / Hyprland). Managed with [GNU Stow](https://www.gnu.org/software/stow/).

Style inspired by [dmmulroy/.dotfiles](https://github.com/dmmulroy/.dotfiles): `home/` mirrors `~`, one-plugin-per-file Neovim config, small `dot` helper.

## What's included

| Tool | Path | Notes |
|------|------|-------|
| Neovim | `home/.config/nvim` | dmmulroy-style base + personal navigation keymaps |
| Fish | `home/.config/fish` | Dillon-style conf.d + functions + git abbrs |
| Ghostty | `home/.config/ghostty` | Starts fish |
| Tmux | `home/.config/tmux` | `C-s` prefix; default shell fish |
| Herdr | `home/.config/herdr` | Workspace/tab/pane manager (fish shell) |
| MPV | `home/.config/mpv` | Full player setup (uosc, scripts, shaders) |
| Git | `home/.gitconfig` + `home/.config/git` | Aliases + difftastic |
| Starship | `home/.config/starship.toml` | Prompt |

## Quick start

```bash
# dependencies
# Arch: sudo pacman -S stow neovim tmux zsh starship ripgrep fd fzf

git clone https://github.com/v36372/dot.git ~/.dotfiles
cd ~/.dotfiles

# backup anything that would be overwritten, then:
./dot stow

# optional: put `dot` on PATH
ln -sf ~/.dotfiles/dot ~/.local/bin/dot
```

If stow refuses because a real file already exists:

```bash
# example: backup existing nvim and re-stow
mv ~/.config/nvim ~/.config/nvim.bak.$(date +%s)
./dot stow
```

## Neovim

Entry: `require("config")`.

```
nvim/
├── init.lua
├── lua/config/          # options, keymaps, lazy bootstrap, utils
└── lua/plugins/         # 1 file per plugin (lazy.nvim specs)
```

### Navigation keymaps (muscle memory)

| Key | Action |
|-----|--------|
| `<C-p>` | Find files |
| `<leader>ss` | Live grep (project string search) |
| `<leader>sw` | Grep word under cursor |
| `<C-f>` / `<leader>/` | Search in current buffer |
| `<leader>e` / `<leader>fp` | Snacks explorer (reveal current file) |
| `gd` | Go to definition |
| `<C-o>` / `<C-i>` | Jump back / forward |
| `<leader>gd` | Definition in **vsplit** |
| `<leader>gD` | Definition in **hsplit** |
| `<C-v>` (normal) | Vsplit + tag jump |
| Telescope `<C-v>` / `<C-c>` | Open result in vsplit / hsplit |
| Explorer `v` / `s` or `<C-v>` / `<C-c>` | Open file in vsplit / hsplit |
| `<C-w>` / `<C-q>` | Save / save+quit |
| `jj` | Exit insert |
| `H` / `L` | Line start / end |
| `gr` / `gi` | References / implementations (Telescope) |
| `<leader>l*` | Allaman-style LSP cluster |

No neo-tree. File browsing is **Snacks explorer**. Fuzzy finding is **Telescope**.

## Layout

```
.dotfiles/
├── dot                 # helper: stow / doctor
├── home/               # stowed into ~
│   ├── .config/
│   │   ├── nvim/
│   │   ├── ghostty/
│   │   ├── tmux/
│   │   ├── herdr/
│   │   ├── mpv/
│   │   ├── git/
│   │   └── starship.toml
│   ├── .zshrc
│   ├── .gitconfig
│   └── .gitignore_global
├── packages/           # optional notes / brew-like lists
└── README.md
```

## Commands

```bash
./dot stow      # symlink everything
./dot restow    # same (re-stow)
./dot unstow    # remove symlinks
./dot doctor    # check tools + links
```

## Notes

- **Do not edit** `~/.config/*` when stowed — edit files under `~/.dotfiles/home/` (or follow the symlink).
- Shell is **Fish** (Dillon-style). Ghostty/tmux/herdr start fish; interactive bash execs fish as a bridge.
- User-local fish may live at `~/.local/bin/fish` until `sudo pacman -S fish` + `chsh`.
- Hyprland / Omarchy desktop config stays outside this repo (managed by Omarchy).
