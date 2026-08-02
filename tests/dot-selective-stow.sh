#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TARGET="$(mktemp -d)"
trap 'rm -rf "$TARGET"' EXIT

HOME="$TARGET" "$ROOT/dot" stow fish >/dev/null
[[ -L "$TARGET/.config/fish/config.fish" ]]
[[ ! -e "$TARGET/.config/nvim" ]]
[[ ! -e "$TARGET/.agents" ]]

HOME="$TARGET" "$ROOT/dot" stow skills >/dev/null
[[ -L "$TARGET/.agents/.skill-lock.json" ]]

HOME="$TARGET" "$ROOT/dot" unstow fish >/dev/null
[[ ! -e "$TARGET/.config/fish/config.fish" ]]
[[ -L "$TARGET/.agents/.skill-lock.json" ]]

echo "selective stow checks passed"
