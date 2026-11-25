# DOTFILES

Personal Linux (Omarchy) env via GNU Stow. Fish + Neovim + Tmux + Herdr + Ghostty + MPV.

## STRUCTURE

```
.dotfiles/
├── dot/bin/dot             # CLI: init/update/doctor/stow
├── home/.agents/           # Skill lock (installed files stay outside the repo)
├── home/.config/
│   ├── nvim/               # Editor (see nvim AGENTS)
│   ├── fish/               # Shell (see fish/AGENTS.md)
│   ├── tmux/               # Prefix C-s, default shell fish
│   ├── ghostty/            # command = fish; shaders/
│   ├── herdr/              # Prefix C-;, default_shell fish
│   ├── rex/                # Prefix C-s, Lua config
│   ├── mpv/
│   ├── git/
│   └── starship.toml
├── home/.gitconfig
└── packages/
    ├── herdr-toggle-popup/  # local Herdr float popup plugin (not stowed)
    └── herdr-companion/     # cursor-following agent status pill (not stowed)
```

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Neovim plugin | `home/.config/nvim/lua/plugins/<name>.lua` |
| Neovim keymap | `home/.config/nvim/lua/config/keymaps.lua` |
| Neovim option | `home/.config/nvim/lua/config/options.lua` |
| Shell alias | `home/.config/fish/conf.d/aliases.fish` |
| Shell function | `home/.config/fish/functions/<name>.fish` |
| Tmux | `home/.config/tmux/tmux.conf` |
| Herdr | `home/.config/herdr/config.toml` |
| Rex keymap | `home/.config/rex/v36372/keymaps.lua` |
| Herdr float popup plugin | `packages/herdr-toggle-popup/` |
| Herdr companion overlay | `packages/herdr-companion/` |
| Ghostty | `home/.config/ghostty/config`, `home/.config/ghostty/shaders/` |
| Git | `home/.gitconfig` |
| Agent skill | `dot add-skill <github-skill-url>` → `home/.agents/.skill-lock.json` |

## CONVENTIONS

- Stow layout: `home/` mirrors `~`
- Neovim: 1 plugin per file in `lua/plugins/`, returns lazy.nvim spec
- Keymaps: navigation-first (search, def, back, splits)
- No neo-tree — use Snacks explorer
- Fuzzy: Telescope

## ANTI-PATTERNS

- Edit `~/.config/*` real files while stowed (edit through symlink / repo)
- Add shared skills under `~/.pi/agent/skills`; use `dot add-skill`
- Re-adding neo-tree / oil as primary explorer without asking
- Hardcoding machine-specific absolute paths under `/Users/...` or old macOS paths
- Committing herdr logs/sockets or mpv memo history

## COMMANDS

```bash
dot stow                      # link home/ (all configs)
dot init --only herdr_app      # select OS-specific desktop files
dot init --only herdr_plugins  # build/link local Herdr plugins
dot add-skill <github-skill-url>
dot remove-skill <name>
dot skills-sync               # restore/update third-party skills from the lock
dot doctor                    # check machine components
```

## NVIM KEY BINDINGS (IMPORTANT)

| Key | Action |
|-----|--------|
| `<C-p>` | Find files |
| `<leader>ss` | Live grep |
| `<leader>sw` | Word under cursor (project) |
| `<C-f>` | Buffer search |
| `<leader>e` | Snacks explorer (reveal file) |
| `gd` | Definition |
| `<C-o>` | Jump back |
| `<leader>gd` / `<leader>gD` | Def in vsplit / hsplit |
| Telescope/Explorer `<C-v>` / `<C-c>` | Open in vsplit / hsplit |
| `<C-w>` / `<C-q>` | Save / save+quit |

## THEME

Tokyo Night Storm across Ghostty, Neovim, Fish, Tmux, Herdr, and Pi.
