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

# Simulate a repo move: existing links point outside the current package path.
rm -rf "$TARGET/.agents"
mkdir -p "$TARGET/.agents"
ln -s /tmp/old-dotfiles-agents-skills "$TARGET/.agents/skills"
ln -s /tmp/old-dotfiles-agents-lock "$TARGET/.agents/.skill-lock.json"
ln -s /tmp/old-dotfiles-agents-readme "$TARGET/.agents/README.md"

HOME="$TARGET" "$ROOT/dot" stow agents >/dev/null
[[ -L "$TARGET/.agents/skills" ]]
[[ "$(readlink -f "$TARGET/.agents/skills")" == "$(readlink -f "$ROOT/home/.agents/skills")" ]]
[[ "$(readlink -f "$TARGET/.agents/.skill-lock.json")" == "$(readlink -f "$ROOT/home/.agents/.skill-lock.json")" ]]

echo "selective stow checks passed"
