#!/usr/bin/env bash
set -euo pipefail

# Update every globally locked skill, regardless of its upstream source.
# The skills CLI reads ~/.agents/.skill-lock.json, groups entries by source,
# and refreshes only skills whose upstream folder hash changed. Personal skills
# without lock entries are left untouched.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd -P)"
LOCK_FILE="$DOTFILES_ROOT/home/.agents/.skill-lock.json"
SKILLS_CLI_VERSION="${SKILLS_CLI_VERSION:-latest}"
NPM_CACHE_DIR="${NPM_CACHE_DIR:-$HOME/.cache/npm}"

if [[ ! -e "$HOME/.agents" ]] || [[ "$(cd "$HOME/.agents" && pwd -P)" != "$DOTFILES_ROOT/home/.agents" ]]; then
  echo "error: ~/.agents is not stowed from this repository" >&2
  echo "run: $DOTFILES_ROOT/dot stow" >&2
  exit 1
fi

locked_count="$(python3 - "$LOCK_FILE" <<'PY'
import json
import sys
from pathlib import Path

lock_path = Path(sys.argv[1])
try:
    skills = json.loads(lock_path.read_text())["skills"]
except FileNotFoundError:
    print(f"error: skill lock not found: {lock_path}", file=sys.stderr)
    raise SystemExit(1)
except (KeyError, json.JSONDecodeError) as error:
    print(f"error: invalid skill lock: {error}", file=sys.stderr)
    raise SystemExit(1)

if not skills:
    print("error: skill lock contains no upstream skills", file=sys.stderr)
    raise SystemExit(1)

print(len(skills))
PY
)"

mkdir -p "$NPM_CACHE_DIR"

echo "Checking $locked_count locked skills from all upstream sources..."
NPM_CONFIG_CACHE="$NPM_CACHE_DIR" npx --yes "skills@$SKILLS_CLI_VERSION" update \
  --global \
  --yes

echo
echo "Skill sync complete. Review changes with:"
echo "  git -C \"$DOTFILES_ROOT\" diff -- home/.agents"
