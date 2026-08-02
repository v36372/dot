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
| Herdr float popup | `packages/herdr-toggle-popup` | Local plugin: persistent 80% float (`ctrl+n`) |
| MPV | `home/.config/mpv` | Full player setup (uosc, scripts, shaders) |
| Git | `home/.gitconfig` + `home/.config/git` | Aliases + difftastic |
| Starship | `home/.config/starship.toml` | Prompt |
| Agent skills | `home/.agents/skills` | Shared skills discovered by Pi and other Agent Skills clients |

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
│   ├── .agents/skills/ # shared Agent Skills
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
./dot stow                 # symlink everything (+ best-effort herdr float plugin)
./dot stow fish            # symlink only Fish
./dot stow agents          # symlink only shared agent skills
./dot stow fish nvim tmux  # symlink several parts
./dot unstow fish          # remove only Fish symlinks
./dot components           # list selectable parts
./dot herdr-plugin  # build/link packages/herdr-toggle-popup
./dot skills-sync   # update locked third-party skills
./dot doctor        # check tools + links + herdr plugin
```

Selectable parts are `agents`, `fish`, `ghostty`, `git`, `herdr`, `mpv`,
`nvim`, `pi`, `starship`, and `tmux`. `skills` and `agent-skills` are aliases
for `agents`. With no part, `stow`, `restow`, and `unstow` still operate on
the complete suite. The Herdr popup plugin is attempted only when `herdr` is
selected (or when stowing everything).

## Agent skills

Skills are committed under `home/.agents/skills` and stowed to the shared
`~/.agents/skills` location. Third-party source metadata lives in
`home/.agents/.skill-lock.json` and is maintained by the `skills` CLI.

```bash
./dot skills-sync

git diff -- home/.agents
```

The sync command updates every skill recorded in the lock, grouping entries by
their upstream source. Personal skills without lock entries are untouched.
Review the resulting diff before committing upstream changes.

Add a skill by pasting the GitHub URL of its skill directory (or SKILL.md):

```bash
./dot add-skill https://github.com/owner/repo/tree/main/path/to/skill
# or: skill-add https://github.com/owner/repo/tree/main/path/to/skill
```

The helper vendors into `home/.agents`, records source metadata in the lock,
and syncs out to `~/.agents`. Subsequent `./dot skills-sync` runs include the
new skill automatically.

## Notes

- **Do not edit** `~/.config/*` when stowed — edit files under `~/.dotfiles/home/` (or follow the symlink).
- Pi discovers the stowed skills directly from `~/.agents/skills`; `~/.pi/agent/skills` is no longer used.
- Shell is **Fish** (Dillon-style). Ghostty/tmux/herdr start fish; interactive bash execs fish as a bridge.
- User-local fish may live at `~/.local/bin/fish` until `sudo pacman -S fish` + `chsh`.
- Hyprland / Omarchy desktop config stays outside this repo (managed by Omarchy).
