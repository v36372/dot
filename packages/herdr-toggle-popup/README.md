# herdr-toggle-popup (local float)

Personal fork of [maro114510/herdr-toggle-popup](https://github.com/maro114510/herdr-toggle-popup).

Differences from upstream:

- uses Herdr `placement = "popup"` (real float) instead of fullscreen `overlay`
- default size `80%` × `80%`
- default shell is **fish** (config `shell = "fish"`), not `$SHELL` / zsh
- injects workspace/tab/cwd env so the popup shell stays alive
- in-popup `ctrl+l` hide bind (Herdr modals swallow outer keybinds)
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
key = "ctrl+l"
type = "plugin_action"
command = "local.toggle-popup.toggle-shell"
description = "Toggle floating terminal (persistent)"
```

## Use

| Action | Result |
|--------|--------|
| `ctrl+l` outside float | open 80% float |
| `ctrl+l` inside float (after ~0.4s) | hide float; shell stays in tmux |
| hard reset shell | `tmux -L herdr-toggle-popup kill-server` |

### Scope (why different workspaces get different shells)

Default `scope = "workspace"`: each Herdr workspace has its own persistent tmux shell.
That is intentional plugin behavior, not a bug.

Herdr's built-in `type = "popup"` keybind is a **session-modal** terminal (one popup UI
in the Herdr session). It does **not** give you one shared persistent shell across
workspaces the way this plugin does — this fork keys shells by workspace/tab/directory.

| `scope` | Shell identity |
|---------|----------------|
| `workspace` (default) | one shell per workspace |
| `tab` | one shell per tab |
| `directory` | one shell per focused pane cwd |

There is no built-in “global one shell everywhere” mode yet; closest is one workspace
you always open the float from, or kill/recreate sessions when you want a clean slate.

## Config

Runtime config: `~/.config/herdr/plugins/config/local.toggle-popup/config.toml`

```toml
shell = "fish"
width = "80%"
height = "80%"
# scope = "workspace"  # default
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
