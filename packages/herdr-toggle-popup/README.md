# herdr-toggle-popup (local float)

Personal fork of [maro114510/herdr-toggle-popup](https://github.com/maro114510/herdr-toggle-popup).

Differences from upstream:

- uses Herdr `placement = "popup"` (real float) instead of fullscreen `overlay`
- default size `80%` × `80%`
- default shell is **fish** (config `shell = "fish"`), not `$SHELL` / zsh
- injects workspace/tab/cwd env so the popup shell stays alive
- in-popup `ctrl+n` hide bind (Herdr modals swallow outer keybinds)
- private low-latency tmux server for shell persistence

## Install / link

Preferred (from the dotfiles root):

```bash
./dot stow            # configs + best-effort plugin install
# or explicitly:
./dot herdr-plugin    # build, link, seed config
./dot doctor          # verify plugin is linked
```

Manual:

```bash
cd packages/herdr-toggle-popup
go build -o bin/toggle-popup .
herdr plugin link "$PWD"
mkdir -p ~/.config/herdr/plugins/config/local.toggle-popup
cp config/config.toml ~/.config/herdr/plugins/config/local.toggle-popup/config.toml
```

Keybinding lives in `home/.config/herdr/config.toml`:

```toml
[[keys.command]]
key = "ctrl+n"
type = "plugin_action"
command = "local.toggle-popup.toggle-shell"
description = "Toggle floating terminal (persistent)"
```

## Use

| Action | Result |
|--------|--------|
| `ctrl+n` outside float | open 80% float |
| `ctrl+n` inside float (after ~0.4s) | hide float; shell stays in tmux |
| hard reset shell | `tmux -L herdr-toggle-popup kill-server` |

### Scope

Default `scope = "global"`: **one** persistent shell shared across every workspace.

| `scope` | Shell identity |
|---------|----------------|
| `global` (default) | one shell for the whole Herdr session |
| `workspace` | one shell per workspace |
| `tab` | one shell per tab |
| `directory` | one shell per focused pane cwd |

Changing scope only affects *new* tmux sessions. Reset with:

```bash
tmux -L herdr-toggle-popup kill-server
```

## Config

Runtime config: `~/.config/herdr/plugins/config/local.toggle-popup/config.toml`

```toml
shell = "fish"
width = "80%"
height = "80%"
scope = "global"
# scope = "workspace"
# scope = "directory"
# scope = "tab"
```

`shell` is intentional: macOS login `$SHELL` is often still `/bin/zsh` even when Herdr/Ghostty use fish. Changing shell requires killing the private tmux server so a new session is created.

## Rebuild after edits

```bash
cd packages/herdr-toggle-popup
go build -o bin/toggle-popup .
```

Herdr loads the linked path; no re-link needed unless the directory moves.

`bin/` is gitignored — build after clone.
