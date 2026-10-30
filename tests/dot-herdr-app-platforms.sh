#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TARGET="$(mktemp -d)"
trap 'rm -rf "$TARGET"' EXIT
mkdir -p "$TARGET/bin" "$TARGET/.config/herdr-app/data"
printf 'runtime state\n' > "$TARGET/.config/herdr-app/data/state"
printf '#!/bin/sh\necho "${TEST_UNAME:?}"\n' > "$TARGET/bin/uname"
chmod +x "$TARGET/bin/uname"
export HOME="$TARGET" PATH="$TARGET/bin:$PATH"

# Migrate the former shared links, including dangling ones after an update.
ln -s "$ROOT/home/.config/herdr-app/keys.json" "$TARGET/.config/herdr-app/keys.json"
printf 'local settings\n' > "$TARGET/.config/herdr-app/settings.json"
export TEST_UNAME=Linux
"$ROOT/dot" stow herdr-app >/dev/null
[[ "$(readlink "$TARGET/.config/herdr-app/keys.json")" == "$ROOT/platforms/herdr-app/linux/keys.json" ]]
[[ "$(readlink "$TARGET/.config/herdr-app/settings.json")" == "$ROOT/platforms/herdr-app/linux/settings.json" ]]
[[ "$(readlink "$TARGET/.config/herdr-app/mods/herdr-prefix")" == "$ROOT/platforms/herdr-app/linux/mods/herdr-prefix" ]]
backups=("$TARGET"/.config/herdr-app/settings.json.bak.*)
[[ "${#backups[@]}" -eq 1 && "$(<"${backups[0]}")" == 'local settings' ]]

export TEST_UNAME=Darwin
"$ROOT/dot" stow herdr-app >/dev/null
[[ "$(readlink "$TARGET/.config/herdr-app/keys.json")" == "$ROOT/platforms/herdr-app/macos/keys.json" ]]
[[ "$(readlink "$TARGET/.config/herdr-app/settings.json")" == "$ROOT/platforms/herdr-app/macos/settings.json" ]]
[[ ! -e "$TARGET/.config/herdr-app/mods/herdr-prefix" ]]
"$ROOT/dot" stow herdr-app >/dev/null
"$ROOT/dot" unstow herdr-app >/dev/null
[[ ! -L "$TARGET/.config/herdr-app/keys.json" ]]
[[ ! -L "$TARGET/.config/herdr-app/settings.json" ]]
[[ "$(<"$TARGET/.config/herdr-app/data/state")" == 'runtime state' ]]
printf 'herdr-app platform checks passed\n'
