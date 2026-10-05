---
name: omarchy-plugins
description: Omarchy Quattro shell plugins. Use when the user mentions an Omarchy plugin or wants to write, clone, modify, debug, install, or validate a plugin for omarchy-shell.
---

# Omarchy Quattro plugins

Treat the installed `omarchy-shell` as the runtime contract; the linked Quattro docs describe the intended contract. A plugin runs QML inside the long-lived Quickshell process, with user-level file and process access. Review third-party code before enabling it.

## 1. Find the right starting point

Identify whether the task is a new plugin, a built-in clone, or a one-off bar module. For a small command/text or QML bar addition, check the [custom bar modules section](https://github.com/omacom/omarchy/blob/quattro/docs/omarchy-shell.md#custom-bar-modules) before creating a plugin. For changes to a built-in, use `omarchy plugin clone <omarchy.id>` rather than editing `$OMARCHY_PATH/shell/plugins/`; the clone is installed and enabled under a user-prefixed id.

Read the relevant [shell reference](https://github.com/omacom/omarchy/blob/quattro/docs/omarchy-shell.md) and the [first-party catalog](https://github.com/omacom/omarchy/blob/quattro/shell/plugins/README.md). If Omarchy is installed, inspect `omarchy plugin list --json`, the installed manifest/QML for a similar kind under `$OMARCHY_PATH/shell/plugins/`, and the host interfaces it uses. Built-ins have trusted host objects; new third-party plugins get scoped facades and clones retain only source-specific capabilities. Copy a built-in's *UI pattern*, checking its host calls against the access available to the target plugin. Check the installed version against Quattro before relying on an example. Complete when the kind, target directory, host access, and a comparable working example are identified.

## 2. Write the smallest plugin

For a new plugin, put `manifest.json` at the root of its directory (also the root of its git repo if distributing it). Declare `schemaVersion: 1`, a non-`omarchy.*` `id`, `name`, `version`, a nonempty `kinds` array, and `entryPoints` with an existing, safe relative QML path for **each** kind. Entry-point keys are `barWidget` for `bar-widget`, and `bar`, `panel`, `overlay`, `menu`, or `service` for the others. A bar widget also declares `barWidget` metadata (`displayName`, `category`, `allowMultiple`, optionally `defaultSection` of `left`, `center`, or `right`, defaults and settings schema). Keep the plugin folder free of internal symlinks. Use the [manifest example](https://github.com/omacom/omarchy/blob/quattro/docs/omarchy-shell.md#plugin-manifest) for field shapes; consult the [registry implementation](https://github.com/omacom/omarchy/blob/quattro/shell/services/PluginRegistry.qml) when a validation rule is unclear.

Implement each entry point as a QML `Item` (a bar widget can use `BarWidget` from `qs.Ui`). Summoned `panel`, `overlay`, and `menu` entry points implement `open(payloadJson)` and `close()`. Follow an installed example of the same kind for injected properties and QML imports, using only the capabilities available to the target plugin. `keepLoaded: true` is for components that must survive between summons; a kept service needs a shell restart for code changes. Complete when every declared kind has a QML entry point and its manifest agrees with the files on disk.

## 3. Validate and exercise

Run `omarchy plugin validate <plugin-directory>` and fix every reported error. For a local plugin, install under `~/.config/omarchy/plugins/<id>/`, run `omarchy-shell shell rescanPlugins`, then `omarchy plugin enable <id>`; saving files there hot-reloads plugin code. For a published plugin, `omarchy plugin add <git-url>` clones the repo; inspect it before enabling. Use `omarchy plugin list` to confirm discovery. When a shell is running, exercise the actual behavior (for example, `omarchy-shell shell summon <id> '{}'` for a summoned surface, or check a widget on the bar), including the close or reload path. Report validation output and any runtime behavior that could not be exercised. Complete when validation passes and the relevant shell behavior is observed, or the unavailable runtime is explicitly noted.

For lifecycle details (add, clone, update, remove, and publication), consult [Writing your own / Shell Plugins](https://github.com/omacom/omarchy/blob/quattro/manual/32-shell-plugins.md#writing-your-own).
