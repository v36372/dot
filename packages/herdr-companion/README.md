# Herdr Companion

A cursor-following status pill for [Herdr](https://herdr.dev) agents. Same idea as the Pi Glimpse companion: a translucent overlay that follows the pointer and shows what your agents are doing.

Each row is **agent** (bright) and **workspace** (muted), plus elapsed time on the right. Working is the running cat. When an agent is blocked, a Needs you chip appears and the request brief is the second line — not a generic “needs your input”.

Working cats run back and forth in a 6-cell track (same RunCat frames as the Pi `cat.ts` spinner, 120ms). Blocked cats sit still with a warm glow.

## What you see

| Herdr status | Pill |
| --- | --- |
| `working` | running cat, `pi · assets`, elapsed |
| `working` + a question dialog | treated as blocked (Pi stays `working` during `ask_user_question`) |
| `blocked` | warm glowing cat, `claude · iam`, Needs you chip, then e.g. `Approve git push origin main --force` |
| `done` | sitting cat, Done chip, frozen elapsed for a few seconds |
| `idle` | hidden |

Idle agents stay off the overlay. Several working or blocked agents stack in one pill. Blocked rows glow so they are hard to miss.

## Install

Requires Herdr 0.9.0+ and Node 18+.

Preferred (from the dotfiles root):

```bash
./dot stow            # configs + best-effort plugin install
# or explicitly:
./dot herdr-plugin    # npm ci + link companion and the float popup
./dot doctor          # verify plugin is linked
```

Manual:

```bash
cd packages/herdr-companion
npm ci
herdr plugin link "$PWD"
```

The overlay starts on the next Herdr server start, or the next agent status change. To preview it without waiting:

```bash
herdr plugin action invoke local.companion.demo
```

Keybinding lives in `home/.config/herdr/config.toml`:

```toml
[[keys.command]]
key = "prefix+shift+c"
type = "plugin_action"
command = "local.companion.toggle"
description = "Toggle companion overlay"
```

## Actions

```bash
herdr plugin action invoke local.companion.toggle
herdr plugin action invoke local.companion.start
herdr plugin action invoke local.companion.stop
herdr plugin action invoke local.companion.demo
```

`stop` writes a `disabled` marker in the plugin config dir so Herdr will not spawn the overlay again until `start` or `toggle`. Config dir:

```bash
herdr plugin config-dir local.companion
```

## How it works

Herdr plugin v1 has no native overlay API. This plugin follows the same pattern as [herdr-pets](https://github.com/hmu332233/herdr-pets) and [herdr-glow](https://github.com/DevooKim/herdr-glow):

1. `[[startup]]` and `pane.agent_status_changed` / `pane.closed` / `pane.exited` / `pane.agent_detected` run `src/launch.mjs`.
2. That process is one-shot. It starts a singleton Glimpse window (`src/companion.mjs`) if needed and pokes it over a Unix socket.
3. The window polls `herdr agent list` and `herdr workspace list`.
4. For `blocked` agents it reads the pane (`detection`, then `visible`, then recent scrollback) and extracts a one-line request.

Briefs prefer, in order:

1. `state_labels.blocked` or pane tokens (`brief`, `question`, `summary`, `request`)
2. Agent-specific screen parsing (Claude, Codex, Cursor, Grok, Antigravity, Pi)
3. The last real question or command above the approval chrome

Generic labels such as “needs your input” are ignored so the pill can fall through to the screen text.

## Uninstall

```bash
herdr plugin action invoke local.companion.stop
herdr plugin unlink local.companion
```
