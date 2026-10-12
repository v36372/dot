#!/usr/bin/env bash
# Remove a vendored or personal skill from the repo and ~/.agents, including
# its upstream lock entries. The repo is the source of truth.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd -P)"

usage() {
  cat <<'EOF'
Usage: remove-skill <name>

  name  Folder name under home/.agents/skills (not a path or URL).

Removes the skill and matching lock entries from the repo and ~/.agents.
Personal skills without lock entries can also be removed.

Example:
  ./dot remove-skill poteto-mode
EOF
}

[[ $# -ge 1 ]] || { usage; exit 2; }
case "$1" in
  -h|--help) usage; exit 0 ;;
esac
[[ $# -eq 1 ]] || { echo "error: expected a single skill name" >&2; usage; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "error: python3 is required" >&2; exit 1; }

python3 - "$DOTFILES_ROOT/home/.agents" "$HOME/.agents" "$1" <<'PY'
import json
import re
import shutil
import sys
from pathlib import Path, PurePosixPath

repo_agents = Path(sys.argv[1])
home_agents = Path(sys.argv[2])
name = sys.argv[3]
repo_skills = repo_agents / "skills"


def valid_folder(value):
    return re.fullmatch(r"[a-zA-Z0-9][a-zA-Z0-9._-]*", value) is not None


def sanitize(value):
    value = re.sub(r"[^a-z0-9._]+", "-", value.lower()).strip(".-")
    return value[:255] or "unnamed-skill"


def load_lock(path):
    if not path.exists() and not path.is_symlink():
        return None
    try:
        lock = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, ValueError) as error:
        raise SystemExit(f"error: invalid skill lock {path}: {error}")
    if not isinstance(lock, dict) or not isinstance(lock.get("skills"), dict):
        raise SystemExit(f"error: invalid skill lock {path}: missing skills object")
    for entry in lock["skills"].values():
        if not isinstance(entry, dict) or not isinstance(entry.get("skillPath", ""), (str, type(None))):
            raise SystemExit(f"error: invalid skill lock {path}: invalid skill entry")
    return lock


def matching_keys(lock):
    if lock is None:
        return []
    matches = []
    for key, entry in lock["skills"].items():
        path = (entry.get("skillPath") or "").replace("\\", "/")
        folder = PurePosixPath(path).parent.name if path.lower().endswith("/skill.md") else None
        # Match the same folder precedence used by skills-sync, including
        # upstream display names and CLI-sanitized installation names.
        candidates = [candidate for candidate in (folder, sanitize(key), key)
                      if candidate and valid_folder(candidate)]
        installed = next((candidate for candidate in candidates
                          if (repo_skills / candidate).is_dir()), None)
        if (installed or folder or sanitize(key)) == name:
            matches.append(key)
    return matches


def main():
    if not valid_folder(name) or name.lower() == "scripts":
        raise SystemExit("error: expected a skill folder name (the scripts directory is reserved)")
    if not repo_skills.is_dir():
        raise SystemExit(f"error: repo skills directory missing: {repo_skills}")

    repo_skill = repo_skills / name
    repo_lock_path = repo_agents / ".skill-lock.json"
    repo_lock = load_lock(repo_lock_path)
    repo_keys = matching_keys(repo_lock)
    if not repo_skill.exists() and not repo_skill.is_symlink() and not repo_keys:
        raise SystemExit(f"error: skill not found: {name}")

    # Validate both locks and deletion targets before making any changes.
    locks = [(repo_lock_path, repo_lock, repo_keys)]
    home_lock_path = home_agents / ".skill-lock.json"
    if home_lock_path.resolve() != repo_lock_path.resolve():
        home_lock = load_lock(home_lock_path)
        locks.append((home_lock_path, home_lock, matching_keys(home_lock)))

    targets = [repo_skill]
    home_skills = home_agents / "skills"
    # Stow may link .agents or skills as a whole. Never delete through that
    # parent link a second time, and leave the shared directory link intact.
    if home_skills.resolve() != repo_skills.resolve():
        targets.append(home_skills / name)
    for target in targets:
        if target.exists() and not target.is_symlink() and not target.is_dir():
            raise SystemExit(f"error: skill path is not a directory: {target}")

    for target in targets:
        if target.is_symlink():
            target.unlink()
        elif target.is_dir():
            shutil.rmtree(target)
        else:
            continue
        print(f"  removed {target}")

    for path, lock, keys in locks:
        if not keys:
            continue
        for key in keys:
            del lock["skills"][key]
        # Keep stowed repo lock links; detach unrelated home lock symlinks
        # rather than changing their external target.
        if path == home_lock_path and path.is_symlink():
            path.unlink()
        path.write_text(json.dumps(lock, indent=2) + "\n", encoding="utf-8")
        print(f"  removed lock entries from {path}: {', '.join(keys)}")


try:
    main()
except OSError as error:
    raise SystemExit(f"error: {error}")
PY

echo "Removed $1. Review: git -C \"$DOTFILES_ROOT\" diff -- home/.agents"
