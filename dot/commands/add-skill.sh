cmd_add_skill_usage() {
    printf 'USAGE:\n    %s add-skill GITHUB_SKILL_URL\n\nInstall a GitHub skill into ~/.agents/skills and record it in the shared lock.\n' "$SCRIPT_NAME"
}

cmd_add_skill() {
    if [[ $# -ne 1 || ( "$1" != https://github.com/*/*/tree/*/* && "$1" != https://github.com/*/*/blob/*/*/SKILL.md ) ]]; then
        cmd_add_skill_usage >&2
        return 1
    fi
    __acquire_run_lock && __require_skills_home || return 1
    __run_skills add "$1" --global --agent pi --yes
}
