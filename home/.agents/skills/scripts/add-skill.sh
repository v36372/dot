#!/usr/bin/env bash
# Add upstream skills into this repo's home/.agents tree (source of truth),
# then sync them out to ~/.agents.
#
# Usage:
#   add-skill.sh <owner/repo|url|path> <skills-dir-path> [skill-name ...]
#
# Examples:
#   add-skill.sh cursor/plugins pstack/skills
#   add-skill.sh cursor/plugins pstack/skills how why
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
Usage: add-skill <repo> <skills-dir-path> [skill-name ...]

  repo             owner/repo, git URL, or local path
  skills-dir-path  directory within the source that contains skill folders
  skill-name       optional folder or frontmatter name; omit to add all

Examples:
  ./dot add-skill cursor/plugins pstack/skills
  ./dot add-skill cursor/plugins pstack/skills how
  ./dot add-skill mattpocock/skills skills/engineering code-review
EOF
}

die() {
  echo "error: $*" >&2
  exit 1
}

normalize_dir() {
  local p="${1%/}"
  p="${p#./}"
  printf '%s\n' "$p"
}

is_github_slug() {
  [[ "$1" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]
}

github_slug_from_url() {
  local url="$1"
  if [[ "$url" =~ github\.com[:/]([^/]+)/([^/.]+)(\.git)?$ ]]; then
    printf '%s/%s\n' "${BASH_REMATCH[1]}" "${BASH_REMATCH[2]}"
    return 0
  fi
  return 1
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

# Materialize source/skills_dir locally; print absolute root path.
materialize_skills_root() {
  local source="$1"
  local skills_dir="$2"

  if [[ -d "$source" ]]; then
    local root
    root="$(cd "$source" && pwd -P)"
    [[ -d "$root/$skills_dir" ]] || die "skills dir not found: $root/$skills_dir"
    printf '%s\n' "$root"
    return 0
  fi

  command -v git >/dev/null 2>&1 || die "git is required to discover skills from $source"
  local tmp_clone git_url
  tmp_clone="$(mktemp -d "${TMPDIR:-/tmp}/dot-add-skill-src.XXXXXX")"
  MATERIALIZE_TMP="$tmp_clone"
  git_url="$source"
  if is_github_slug "$source"; then
    git_url="https://github.com/${source}.git"
  fi
  git clone --depth 1 --filter=blob:none --sparse "$git_url" "$tmp_clone" >/dev/null 2>&1 \
    || die "failed to clone $git_url"
  (
    cd "$tmp_clone"
    git sparse-checkout set "$skills_dir" >/dev/null 2>&1 || true
  )
  [[ -d "$tmp_clone/$skills_dir" ]] || die "skills dir not found after clone: $skills_dir"
  printf '%s\n' "$tmp_clone"
}

# Print "folder\tcli_name\trel_path" lines for direct children of skills_dir.
discover_skills() {
  local root="$1"
  local skills_dir="$2"
  local base="$root/$skills_dir"
  local skill_md skill_dir folder cli_name rel

  while IFS= read -r -d '' skill_md; do
    skill_dir="$(dirname "$skill_md")"
    folder="$(basename "$skill_dir")"
    cli_name="$(frontmatter_name "$skill_md")"
    if [[ -z "$cli_name" ]]; then
      cli_name="$folder"
    fi
    rel="${skill_dir#"$root"/}"
    # Only direct skill folders: <skills_dir>/<folder>/SKILL.md
    if [[ "$rel" != "$skills_dir/$folder" ]]; then
      continue
    fi
    printf '%s\t%s\t%s\n' "$folder" "$cli_name" "$rel"
  done < <(find "$base" -mindepth 2 -maxdepth 2 -type f -name SKILL.md -print0 | sort -z)
}

sync_repo_agents_to_home() {
  mkdir -p "$HOME/.agents/skills"
  # Lock + readme: prefer replacing with copies from the repo (SoT).
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

  # Sync skill trees that exist in the repo (skip scripts helper dir).
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
[[ $# -ge 2 ]] || die "skills-dir-path is required"$'\n'"$(usage)"

SOURCE="$1"
SKILLS_DIR="$(normalize_dir "$2")"
shift 2
REQUESTED_SKILLS=("$@")

[[ -d "$REPO_SKILLS" ]] || die "repo skills dir missing: $REPO_SKILLS"
[[ -f "$REPO_LOCK" ]] || die "repo skill lock missing: $REPO_LOCK"

MATERIALIZE_TMP=""
cleanup_materialize() {
  if [[ -n "${MATERIALIZE_TMP:-}" && -d "$MATERIALIZE_TMP" ]]; then
    rm -rf "$MATERIALIZE_TMP"
  fi
}
trap cleanup_materialize EXIT

SOURCE_ROOT="$(materialize_skills_root "$SOURCE" "$SKILLS_DIR")"
mapfile -t DISCOVERED < <(discover_skills "$SOURCE_ROOT" "$SKILLS_DIR")
[[ ${#DISCOVERED[@]} -gt 0 ]] || die "no skills discovered under $SKILLS_DIR"

declare -A FOLDER_TO_CLI=()
declare -A LOOKUP_TO_FOLDER=()
DISCOVERED_FOLDERS=()
for row in "${DISCOVERED[@]}"; do
  folder="${row%%$'\t'*}"
  rest="${row#*$'\t'}"
  cli_name="${rest%%$'\t'*}"
  FOLDER_TO_CLI["$folder"]="$cli_name"
  DISCOVERED_FOLDERS+=("$folder")
  LOOKUP_TO_FOLDER["$folder"]="$folder"
  LOOKUP_TO_FOLDER["${folder,,}"]="$folder"
  LOOKUP_TO_FOLDER["$cli_name"]="$folder"
  LOOKUP_TO_FOLDER["${cli_name,,}"]="$folder"
done

SELECTED_FOLDERS=()
if [[ ${#REQUESTED_SKILLS[@]} -eq 0 ]]; then
  SELECTED_FOLDERS=("${DISCOVERED_FOLDERS[@]}")
else
  for req in "${REQUESTED_SKILLS[@]}"; do
    folder="${LOOKUP_TO_FOLDER[$req]:-}"
    if [[ -z "$folder" ]]; then
      folder="${LOOKUP_TO_FOLDER[${req,,}]:-}"
    fi
    [[ -n "$folder" ]] || die "skill '$req' not found under $SKILLS_DIR"$'\n'"available: ${DISCOVERED_FOLDERS[*]}"
    SELECTED_FOLDERS+=("$folder")
  done
fi

SELECTED_CLI_NAMES=()
for folder in "${SELECTED_FOLDERS[@]}"; do
  SELECTED_CLI_NAMES+=("${FOLDER_TO_CLI[$folder]}")
done

echo "Source:       $SOURCE"
echo "Skills dir:   $SKILLS_DIR"
echo "Installing:   ${SELECTED_FOLDERS[*]}"
echo "Repo target:  $REPO_SKILLS"
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
# Pass frontmatter/install names — folder names miss skills like "Poteto Mode".
env -u XDG_STATE_HOME \
  HOME="$TMP_HOME" \
  NPM_CONFIG_CACHE="$NPM_CACHE_DIR" \
  npx --yes "skills@$SKILLS_CLI_VERSION" add "$SOURCE" \
    --global \
    --agent "$SKILLS_AGENT" \
    --skill "${SELECTED_CLI_NAMES[@]}" \
    --yes

# Merge installed skill folders into the repo.
for folder in "${SELECTED_FOLDERS[@]}"; do
  cli_name="${FOLDER_TO_CLI[$folder]}"
  src="$TMP_HOME/.agents/skills/$folder"
  if [[ ! -d "$src" ]]; then
    sanitized="$(sanitize_name "$cli_name")"
    src="$TMP_HOME/.agents/skills/$sanitized"
  fi
  [[ -d "$src" ]] || die "skills CLI did not install: $folder (cli name: $cli_name)"
  dest="$REPO_SKILLS/$folder"
  rm -rf "$dest"
  mkdir -p "$dest"
  cp -a "$src/." "$dest/"
  echo "  vendored $folder -> home/.agents/skills/$folder"
done

# Merge lock entries by skillPath folder match (lock keys may be display names).
python3 - "$TMP_HOME/.agents/.skill-lock.json" "$REPO_LOCK" "$SKILLS_DIR" "${SELECTED_FOLDERS[@]}" <<'PY'
import json
import sys
from pathlib import Path

tmp_lock_path = Path(sys.argv[1])
repo_lock_path = Path(sys.argv[2])
skills_dir = sys.argv[3].rstrip("/")
selected_folders = sys.argv[4:]

tmp_lock = json.loads(tmp_lock_path.read_text())
repo_lock = json.loads(repo_lock_path.read_text())

if "skills" not in repo_lock or not isinstance(repo_lock["skills"], dict):
    raise SystemExit("error: invalid repo skill lock: missing skills object")

tmp_skills = tmp_lock.get("skills", {})
for folder in selected_folders:
    suffixes = (
        f"{skills_dir}/{folder}/SKILL.md",
        f"{folder}/SKILL.md",
    )
    matched_key = None
    matched_entry = None
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
        raise SystemExit(f"error: skill lock missing entry for folder {folder}")
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
echo "Added ${#SELECTED_FOLDERS[@]} skill(s) to home/.agents and ~/.agents"
echo "Review: git -C \"$DOTFILES_ROOT\" diff -- home/.agents"
