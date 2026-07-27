#!/usr/bin/env bash
# Vendor one upstream skill into this repo's home/.agents tree (source of truth),
# then sync it out to ~/.agents.
#
# Usage:
#   add-skill.sh <github-skill-url>
#
# The URL must point at the directory that contains SKILL.md (GitHub tree page),
# or at SKILL.md itself (blob page).
#
# Examples:
#   ./dot add-skill https://github.com/IgorWarzocha/howaboua-pi-stuff/tree/main/packages/pi-skill-omarchy-help/skills/omarchy-help
#   ./dot add-skill https://github.com/cursor/plugins/tree/main/pstack/skills/how
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
DOTFILES_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd -P)"
REPO_AGENTS="$DOTFILES_ROOT/home/.agents"
REPO_SKILLS="$REPO_AGENTS/skills"
REPO_LOCK="$REPO_AGENTS/.skill-lock.json"
SKILLS_CLI_VERSION="${SKILLS_CLI_VERSION:-latest}"
NPM_CACHE_DIR="${NPM_CACHE_DIR:-$HOME/.cache/npm}"
SKILLS_AGENT="${SKILLS_AGENT:-cline}"

usage() {
  cat <<'EOF'
Usage: add-skill <github-skill-url>

  github-skill-url  GitHub tree URL of the skill directory (contains SKILL.md),
                    or blob URL of SKILL.md itself.

Examples:
  ./dot add-skill https://github.com/IgorWarzocha/howaboua-pi-stuff/tree/main/packages/pi-skill-omarchy-help/skills/omarchy-help
  ./dot add-skill https://github.com/cursor/plugins/tree/main/pstack/skills/how
  ./dot add-skill https://github.com/mattpocock/skills/blob/main/skills/engineering/code-review/SKILL.md
EOF
}

die() {
  echo "error: $*" >&2
  exit 1
}

# Mirror skills CLI sanitizeName(): folder name under ~/.agents/skills.
sanitize_name() {
  python3 -c 'import re,sys; n=sys.argv[1].lower(); n=re.sub(r"[^a-z0-9._]+","-",n); n=re.sub(r"^[.\-]+|[.\-]+$","",n); print((n[:255] or "unnamed-skill"))' "$1"
}

# Read YAML frontmatter `name:` from SKILL.md (empty if absent).
frontmatter_name() {
  python3 - "$1" <<'PY'
import re
import sys
from pathlib import Path

text = Path(sys.argv[1]).read_text(encoding="utf-8")
if not text.startswith("---"):
    print("")
    raise SystemExit(0)
end = text.find("\n---", 3)
if end < 0:
    print("")
    raise SystemExit(0)
fm = text[3:end]
match = re.search(r"(?m)^name:\s*(.+?)\s*$", fm)
if not match:
    print("")
    raise SystemExit(0)
value = match.group(1).strip()
if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
    value = value[1:-1]
print(value)
PY
}

# Parse a GitHub skill URL into: owner repo ref skill_path cli_source
# Prints: owner\trepo\tref\tskill_path\tcli_source
parse_github_skill_url() {
  python3 - "$1" <<'PY'
import re
import sys

raw = sys.argv[1].strip()
url = raw.rstrip("/")

# Blob URL of SKILL.md → treat parent dir as the skill.
blob = re.match(
    r"^https?://github\.com/([^/]+)/([^/]+)/blob/([^/]+)/(.+)/SKILL\.md$",
    url,
    re.IGNORECASE,
)
if blob:
    owner, repo, ref, skill_path = blob.groups()
    repo = re.sub(r"\.git$", "", repo)
    cli_source = f"https://github.com/{owner}/{repo}/tree/{ref}/{skill_path}"
    print(f"{owner}\t{repo}\t{ref}\t{skill_path}\t{cli_source}")
    raise SystemExit(0)

# Tree URL of the skill directory.
tree = re.match(
    r"^https?://github\.com/([^/]+)/([^/]+)/tree/([^/]+)/(.+)$",
    url,
    re.IGNORECASE,
)
if tree:
    owner, repo, ref, skill_path = tree.groups()
    repo = re.sub(r"\.git$", "", repo)
    skill_path = skill_path.rstrip("/")
    if skill_path.lower().endswith("/skill.md"):
        skill_path = skill_path[: -len("/SKILL.md")]
    if not skill_path:
        raise SystemExit("error: URL does not include a skill directory path")
    cli_source = f"https://github.com/{owner}/{repo}/tree/{ref}/{skill_path}"
    print(f"{owner}\t{repo}\t{ref}\t{skill_path}\t{cli_source}")
    raise SystemExit(0)

# Shorthand: owner/repo/path/to/skill (no ref; default branch).
short = re.match(r"^([^/]+)/([^/]+)/(.+)$", url)
if short and "://" not in url and not url.startswith("."):
    owner, repo, skill_path = short.groups()
    repo = re.sub(r"\.git$", "", repo)
    skill_path = skill_path.rstrip("/")
    if skill_path.lower().endswith("/skill.md"):
        skill_path = skill_path[: -len("/SKILL.md")]
    if not skill_path:
        raise SystemExit("error: shorthand URL missing skill directory path")
    cli_source = f"{owner}/{repo}/{skill_path}"
    print(f"{owner}\t{repo}\t\t{skill_path}\t{cli_source}")
    raise SystemExit(0)

raise SystemExit(
    "error: expected a GitHub tree/blob URL pointing at a skill directory\n"
    "  e.g. https://github.com/owner/repo/tree/main/path/to/skill"
)
PY
}

sync_repo_agents_to_home() {
  mkdir -p "$HOME/.agents/skills"
  if [[ -f "$REPO_LOCK" ]]; then
    if [[ -L "$HOME/.agents/.skill-lock.json" ]]; then
      rm -f "$HOME/.agents/.skill-lock.json"
    fi
    cp -f "$REPO_LOCK" "$HOME/.agents/.skill-lock.json"
  fi
  if [[ -f "$REPO_AGENTS/README.md" ]]; then
    if [[ -L "$HOME/.agents/README.md" ]]; then
      rm -f "$HOME/.agents/README.md"
    fi
    cp -f "$REPO_AGENTS/README.md" "$HOME/.agents/README.md"
  fi

  local skill_dir skill_name
  for skill_dir in "$REPO_SKILLS"/*/; do
    [[ -d "$skill_dir" ]] || continue
    skill_name="$(basename "$skill_dir")"
    [[ "$skill_name" == "scripts" ]] && continue
    rm -rf "$HOME/.agents/skills/$skill_name"
    mkdir -p "$HOME/.agents/skills/$skill_name"
    cp -a "$skill_dir." "$HOME/.agents/skills/$skill_name/"
  done
}

[[ $# -ge 1 ]] || { usage; exit 2; }
case "${1:-}" in
  -h|--help) usage; exit 0 ;;
esac
[[ $# -eq 1 ]] || die "expected a single GitHub skill URL"$'\n'"$(usage)"

SKILL_URL="$1"

[[ -d "$REPO_SKILLS" ]] || die "repo skills dir missing: $REPO_SKILLS"
[[ -f "$REPO_LOCK" ]] || die "repo skill lock missing: $REPO_LOCK"

set +e
PARSED="$(parse_github_skill_url "$SKILL_URL" 2>&1)"
parse_status=$?
set -e
[[ $parse_status -eq 0 ]] || die "$PARSED"
IFS=$'\t' read -r OWNER REPO REF SKILL_PATH CLI_SOURCE <<<"$PARSED"
FOLDER="$(basename "$SKILL_PATH")"
GIT_URL="https://github.com/${OWNER}/${REPO}.git"

MATERIALIZE_TMP=""
cleanup_materialize() {
  if [[ -n "${MATERIALIZE_TMP:-}" && -d "$MATERIALIZE_TMP" ]]; then
    rm -rf "$MATERIALIZE_TMP"
  fi
}
trap cleanup_materialize EXIT

command -v git >/dev/null 2>&1 || die "git is required"
MATERIALIZE_TMP="$(mktemp -d "${TMPDIR:-/tmp}/dot-add-skill-src.XXXXXX")"
clone_args=(--depth 1 --filter=blob:none --sparse)
if [[ -n "$REF" ]]; then
  clone_args+=(--branch "$REF")
fi
git clone "${clone_args[@]}" "$GIT_URL" "$MATERIALIZE_TMP" >/dev/null 2>&1 \
  || die "failed to clone $GIT_URL${REF:+ (@ $REF)}"
(
  cd "$MATERIALIZE_TMP"
  git sparse-checkout set "$SKILL_PATH" >/dev/null 2>&1 || true
)

SKILL_MD="$MATERIALIZE_TMP/$SKILL_PATH/SKILL.md"
[[ -f "$SKILL_MD" ]] || die "SKILL.md not found at $SKILL_PATH (from $SKILL_URL)"

CLI_NAME="$(frontmatter_name "$SKILL_MD")"
if [[ -z "$CLI_NAME" ]]; then
  CLI_NAME="$FOLDER"
fi

echo "Source URL:  $SKILL_URL"
echo "CLI source:  $CLI_SOURCE"
echo "Skill path:  $SKILL_PATH"
echo "Installing:  $FOLDER (cli name: $CLI_NAME)"
echo "Repo target: $REPO_SKILLS"
echo

TMP_HOME="$(mktemp -d "${TMPDIR:-/tmp}/dot-add-skill-home.XXXXXX")"
cleanup_all() {
  cleanup_materialize
  rm -rf "$TMP_HOME"
}
trap cleanup_all EXIT

mkdir -p "$TMP_HOME/.agents/skills"
cp -f "$REPO_LOCK" "$TMP_HOME/.agents/.skill-lock.json"
mkdir -p "$NPM_CACHE_DIR"

# skills CLI resolves global skills + lock via homedir(); keep XDG_STATE_HOME out
# so the lock stays under $HOME/.agents/.skill-lock.json.
# Pass the skill-dir URL so discovery is scoped past well-known roots like .pi/skills.
env -u XDG_STATE_HOME \
  HOME="$TMP_HOME" \
  NPM_CONFIG_CACHE="$NPM_CACHE_DIR" \
  npx --yes "skills@$SKILLS_CLI_VERSION" add "$CLI_SOURCE" \
    --global \
    --agent "$SKILLS_AGENT" \
    --skill "$CLI_NAME" \
    --full-depth \
    --yes

src="$TMP_HOME/.agents/skills/$FOLDER"
if [[ ! -d "$src" ]]; then
  src="$TMP_HOME/.agents/skills/$(sanitize_name "$CLI_NAME")"
fi
[[ -d "$src" ]] || die "skills CLI did not install: $FOLDER (cli name: $CLI_NAME)"

dest="$REPO_SKILLS/$FOLDER"
rm -rf "$dest"
mkdir -p "$dest"
cp -a "$src/." "$dest/"
echo "  vendored $FOLDER -> home/.agents/skills/$FOLDER"

# Merge lock entry by skillPath / folder match (lock keys may be display names).
python3 - "$TMP_HOME/.agents/.skill-lock.json" "$REPO_LOCK" "$SKILL_PATH" "$FOLDER" <<'PY'
import json
import sys
from pathlib import Path

tmp_lock_path = Path(sys.argv[1])
repo_lock_path = Path(sys.argv[2])
skill_path = sys.argv[3].rstrip("/")
folder = sys.argv[4]

tmp_lock = json.loads(tmp_lock_path.read_text())
repo_lock = json.loads(repo_lock_path.read_text())

if "skills" not in repo_lock or not isinstance(repo_lock["skills"], dict):
    raise SystemExit("error: invalid repo skill lock: missing skills object")

tmp_skills = tmp_lock.get("skills", {})
suffixes = (
    f"{skill_path}/SKILL.md",
    f"{folder}/SKILL.md",
)
matched_entry = None
matched_key = None
for key, entry in tmp_skills.items():
    path = (entry.get("skillPath") or "").replace("\\", "/")
    if any(path.endswith(suffix) or path == suffix for suffix in suffixes):
        matched_key = key
        matched_entry = entry
        break
    if key == folder or key.lower() == folder.lower():
        matched_key = key
        matched_entry = entry
        break

if matched_entry is None:
    raise SystemExit(f"error: skill lock missing entry for {folder} ({skill_path})")

repo_lock["skills"][matched_key] = matched_entry
repo_lock["skills"] = dict(sorted(repo_lock["skills"].items()))
if "dismissed" not in repo_lock:
    repo_lock["dismissed"] = {}

repo_lock_path.write_text(json.dumps(repo_lock, indent=2) + "\n")
PY

echo
echo "Syncing repo agents -> ~/.agents (repo is source of truth)..."
sync_repo_agents_to_home

echo
echo "Added $FOLDER to home/.agents and ~/.agents"
echo "Review: git -C \"$DOTFILES_ROOT\" diff -- home/.agents"
