# dot

Personal dotfiles for macOS and Linux (including Omarchy). Managed with [GNU Stow](https://www.gnu.org/software/stow/).

The [`dot` CLI](dot/README.md) is forked from [dmmulroy/.dotfiles at `c3a895aa`](https://github.com/dmmulroy/.dotfiles/commit/c3a895aa9077f655532e958235cbf0204d1f4b0a) and adapted for `v36372/dot`.

## What's included

| Tool | Path | Notes |
|------|------|-------|
| Neovim | `home/.config/nvim` | dmmulroy-style base + personal navigation keymaps |
| Fish | `home/.config/fish` | Dillon-style conf.d + functions + git abbrs |
| Ghostty | `home/.config/ghostty` | Starts fish |
| Tmux | `home/.config/tmux` | `C-s` prefix; default shell fish |
| Herdr | `home/.config/herdr` | Workspace/tab/pane manager (fish shell) |
| Herdr app | `platforms/herdr-app` | Per-OS desktop app keys and settings |
| Rex | `home/.config/rex` | `Ctrl+S` prefix, tabs and pane controls |
| Herdr float popup | `packages/herdr-toggle-popup` | Local plugin: persistent 80% float (`ctrl+n`) |
| Herdr companion | `packages/herdr-companion` | Local plugin: cursor-following agent status pill (`prefix+shift+c`) |
| MPV | `home/.config/mpv` | Full player setup (uosc, scripts, shaders) |
| Git | `home/.gitconfig` + `home/.config/git` | Aliases + difftastic |
| Starship | `home/.config/starship.toml` | Prompt |
| Agent skills | `home/.agents/.skill-lock.json` | Lock file for skills installed outside the repo |

## Quick start

```bash
git clone https://github.com/v36372/dot.git ~/.dotfiles
cd ~/.dotfiles

./dot/bin/dot init --dry-run   # preview setup
./dot/bin/dot stow             # link configs only (requires GNU Stow)
./dot/bin/dot skills-sync      # restore third-party skills (requires Node.js)
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
├── dot/bin/dot         # component-based bootstrap CLI
├── home/               # stowed into ~
│   ├── .agents/        # skill lock
│   ├── .config/
│   │   ├── nvim/
│   │   ├── ghostty/
│   │   ├── tmux/
│   │   ├── herdr/
│   │   ├── rex/
│   │   ├── mpv/
│   │   ├── git/
│   │   └── starship.toml
│   ├── .gitconfig
│   └── .gitignore_global
├── packages/           # package lists and local Herdr plugins
└── README.md
```

## Commands

```bash
dot stow                                  # link the entire home/ tree
dot init --only herdr_app                  # link desktop app keys and settings
dot update --no-pull --only herdr_plugins  # build/link the two local plugins
dot components                            # list setup components
dot doctor --only stow,rex                 # check specific components
```

Fish adds `dot` to `PATH` after startup; use `./dot/bin/dot` directly otherwise.
`dot stow` replaces selective stow/unstow. Conflicting files are backed up
under `~/.dot-backup/`. Use `--only` or `--skip` with `init`, `update`, and
`doctor`. The [CLI guide](dot/README.md) covers packages and dry runs.

The `herdr_app` component links the current OS's keys and settings from
`platforms/herdr-app/{linux,macos}/`.
On Linux, Ctrl+S opens the Herdr-prefix mod; press the TUI action key next.
Ctrl+S twice sends a literal Ctrl+S to the focused terminal, including Neovim.
Copy and paste are Ctrl+Shift+C and Ctrl+Shift+V.
Ctrl+H/J/K/L and Alt+H/J/K/L move between Herdr App panes (not Neovim splits);
Herdr captures these chords instead of passing them to terminal programs.

## Rex

```bash
dot stow
rex config check && rex config reload
```

Press `Ctrl+S` and then `/` to split right, `Enter` to split down, or `?`
to open the action palette. `Ctrl+H/J/K/L` focus panes without the prefix;
at the edge the key goes to the terminal. `Ctrl+S` then `Shift+R` enters resize
mode (`Esc` or `Enter` exits). `Ctrl+S` twice sends the chord to the terminal.
`Cmd+N` creates a new Rex session; `Cmd+Shift+N` opens a new macOS window.
Edit `home/.config/rex/v36372/` in this repo, then run the check and reload again.

Optional macOS settings: turn on **Show key sequence hints** under **Settings →
Terminal → Keyboard**. To use the upstream palette, go to **Settings → Themes →
Import Theme** and pick `~/.config/rex/themes/catppuccin-macchiato`.

## Agent skills

Skill files are installed in `~/.agents/skills/`, not committed to the repo.
Git tracks their source metadata in `home/.agents/.skill-lock.json`. After
`dot stow`:

```bash
dot skills-sync   # restore missing entries and update installed skills
dot add-skill https://github.com/owner/repo/tree/main/path/to/skill
dot remove-skill skill-name
git diff -- home/.agents/.skill-lock.json
```

These commands use the [Vercel skills CLI](https://github.com/vercel-labs/skills)
and require Node.js 22.20+. Sync follows upstream refs and updates the lock; it
does not restore an exact historical snapshot.

## Notes

- **Do not edit** `~/.config/*` when stowed — edit files under `~/.dotfiles/home/` (or follow the symlink).
- Pi discovers skills directly from `~/.agents/skills`.
- Shell is **Fish** (Dillon-style). Ghostty/tmux/herdr start fish; interactive bash execs fish as a bridge.
- User-local fish may live at `~/.local/bin/fish` until `sudo pacman -S fish` + `chsh`.
- Hyprland / Omarchy desktop config stays outside this repo (managed by Omarchy).
