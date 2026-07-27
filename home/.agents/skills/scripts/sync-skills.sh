#!/usr/bin/env bash
set -euo pipefail

# Update every locked skill from its upstream source into this repo's
# home/.agents tree (source of truth), then sync out to ~/.agents.
# Personal skills without lock entries are left untouched.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd -P)"
REPO_AGENTS="$DOTFILES_ROOT/home/.agents"
REPO_SKILLS="$REPO_AGENTS/skills"
LOCK_FILE="$REPO_AGENTS/.skill-lock.json"
SKILLS_CLI_VERSION="${SKILLS_CLI_VERSION:-latest}"
NPM_CACHE_DIR="${NPM_CACHE_DIR:-$HOME/.cache/npm}"
SKILLS_AGENT="${SKILLS_AGENT:-cline}"

if [[ ! -f "$LOCK_FILE" ]]; then
  echo "error: skill lock not found: $LOCK_FILE" >&2
  exit 1
fi

locked_names="$(python3 - "$LOCK_FILE" <<'PY'
import json
import sys
from pathlib import Path

lock_path = Path(sys.argv[1])
try:
    skills = json.loads(lock_path.read_text())["skills"]
except (KeyError, json.JSONDecodeError) as error:
    print(f"error: invalid skill lock: {error}", file=sys.stderr)
    raise SystemExit(1)

if not skills:
    print("error: skill lock contains no upstream skills", file=sys.stderr)
    raise SystemExit(1)

for name in sorted(skills):
    print(name)
PY
)"

locked_count="$(grep -c . <<< "$locked_names" || true)"
[[ "$locked_count" -gt 0 ]] || {
  echo "error: skill lock contains no upstream skills" >&2
  exit 1
}

echo "Checking $locked_count locked skills from all upstream sources..."

TMP_HOME="$(mktemp -d "${TMPDIR:-/tmp}/dot-skills-sync.XXXXXX")"
cleanup() {
  rm -rf "$TMP_HOME"
}
trap cleanup EXIT

mkdir -p "$TMP_HOME/.agents/skills"
cp -f "$LOCK_FILE" "$TMP_HOME/.agents/.skill-lock.json"

# Seed currently vendored locked skills so `skills update` can refresh them.
python3 - "$LOCK_FILE" "$REPO_SKILLS" "$TMP_HOME/.agents/skills" <<'PY'
import json
import shutil
import sys
from pathlib import Path

lock = json.loads(Path(sys.argv[1]).read_text())
repo_skills = Path(sys.argv[2])
tmp_skills = Path(sys.argv[3])

def sanitize(name: str) -> str:
    import re
    n = name.lower()
    n = re.sub(r"[^a-z0-9._]+", "-", n)
    n = re.sub(r"^[.\-]+|[.\-]+$", "", n)
    return (n[:255] or "unnamed-skill")

for key, entry in lock.get("skills", {}).items():
    path = (entry.get("skillPath") or "").replace("\\", "/")
    folder = None
    if path.lower().endswith("/skill.md"):
        folder = Path(path).parent.name
    candidates = [folder, sanitize(key), key]
    src = None
    for candidate in candidates:
        if not candidate:
            continue
        maybe = repo_skills / candidate
        if maybe.is_dir():
            src = maybe
            folder = candidate
            break
    if src is None:
        continue
    dest = tmp_skills / folder
    shutil.copytree(src, dest, dirs_exist_ok=True)
PY

mkdir -p "$NPM_CACHE_DIR"

env -u XDG_STATE_HOME \
  HOME="$TMP_HOME" \
  NPM_CONFIG_CACHE="$NPM_CACHE_DIR" \
  npx --yes "skills@$SKILLS_CLI_VERSION" update \
    --global \
    --yes

# Copy refreshed locked skill folders + lock back into the repo.
python3 - "$TMP_HOME/.agents/.skill-lock.json" "$LOCK_FILE" "$TMP_HOME/.agents/skills" "$REPO_SKILLS" <<'PY'
import json
import shutil
import sys
from pathlib import Path

tmp_lock_path = Path(sys.argv[1])
repo_lock_path = Path(sys.argv[2])
tmp_skills = Path(sys.argv[3])
repo_skills = Path(sys.argv[4])

tmp_lock = json.loads(tmp_lock_path.read_text())
repo_lock = json.loads(repo_lock_path.read_text())
repo_lock["skills"] = dict(sorted(tmp_lock.get("skills", {}).items()))
if "dismissed" not in repo_lock:
    repo_lock["dismissed"] = tmp_lock.get("dismissed", {})
repo_lock_path.write_text(json.dumps(repo_lock, indent=2) + "\n")

def sanitize(name: str) -> str:
    import re
    n = name.lower()
    n = re.sub(r"[^a-z0-9._]+", "-", n)
    n = re.sub(r"^[.\-]+|[.\-]+$", "", n)
    return (n[:255] or "unnamed-skill")

for key, entry in repo_lock["skills"].items():
    path = (entry.get("skillPath") or "").replace("\\", "/")
    folder = Path(path).parent.name if path.lower().endswith("/skill.md") else sanitize(key)
    src = tmp_skills / folder
    if not src.is_dir():
        alt = tmp_skills / sanitize(key)
        if alt.is_dir():
            src = alt
            folder = alt.name
    if not src.is_dir():
        print(f"warning: updated skill missing on disk: {key}", file=sys.stderr)
        continue
    dest = repo_skills / folder
    if dest.exists():
        shutil.rmtree(dest)
    shutil.copytree(src, dest)
    print(f"  refreshed {folder}")
PY

# Upstreams sometimes use a display label even though skill names only allow
# lowercase letters, numbers, and hyphens. Use the already-valid folder name.
python3 - "$REPO_SKILLS" <<'PY'
import re
import sys
from pathlib import Path

skills_dir = Path(sys.argv[1])
valid_name = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")

for skill_md in sorted(skills_dir.glob("*/SKILL.md")):
    text = skill_md.read_text(encoding="utf-8")
    match = re.search(r"(?m)^name:\s*(.+?)\s*$", text)
    if not match or valid_name.fullmatch(match.group(1)):
        continue

    folder_name = skill_md.parent.name
    if not valid_name.fullmatch(folder_name):
        raise SystemExit(f"error: invalid skill folder name: {folder_name}")

    text = text[:match.start(1)] + folder_name + text[match.end(1):]
    skill_md.write_text(text, encoding="utf-8")
    print(f"  normalized {folder_name} metadata name")
PY

echo
echo "Syncing repo agents -> ~/.agents (repo is source of truth)..."
mkdir -p "$HOME/.agents/skills"
if [[ -L "$HOME/.agents/.skill-lock.json" ]]; then
  rm -f "$HOME/.agents/.skill-lock.json"
fi
cp -f "$LOCK_FILE" "$HOME/.agents/.skill-lock.json"
if [[ -f "$REPO_AGENTS/README.md" ]]; then
  if [[ -L "$HOME/.agents/README.md" ]]; then
    rm -f "$HOME/.agents/README.md"
  fi
  cp -f "$REPO_AGENTS/README.md" "$HOME/.agents/README.md"
fi
for skill_dir in "$REPO_SKILLS"/*/; do
  [[ -d "$skill_dir" ]] || continue
  skill_name="$(basename "$skill_dir")"
  [[ "$skill_name" == "scripts" ]] && continue
  rm -rf "$HOME/.agents/skills/$skill_name"
  mkdir -p "$HOME/.agents/skills/$skill_name"
  cp -a "$skill_dir." "$HOME/.agents/skills/$skill_name/"
done

echo
echo "Skill sync complete. Review changes with:"
echo "  git -C \"$DOTFILES_ROOT\" diff -- home/.agents"
