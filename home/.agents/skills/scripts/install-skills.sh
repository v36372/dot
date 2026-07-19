#!/usr/bin/env bash
set -euo pipefail

# Skills live in this dotfiles repository and are exposed at
# ~/.agents/skills by GNU Stow. Re-stow the home package instead of copying
# skills into a second location.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd -P)"

exec "$DOTFILES_ROOT/dot" stow
