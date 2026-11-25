cmd_remove_skill_usage() {
    printf 'USAGE:\n    %s remove-skill NAME\n\nRemove a lock-tracked skill and its lock entry.\n' "$SCRIPT_NAME"
}

cmd_remove_skill() {
    if [[ $# -ne 1 || ! "$1" =~ ^[a-zA-Z0-9][a-zA-Z0-9._-]*$ ]]; then
        cmd_remove_skill_usage >&2
        return 1
    fi
    __acquire_run_lock && __require_skills_home || return 1
    if ! node -e 'const lock = require(process.argv[1]); process.exit(Object.hasOwn(lock.skills, process.argv[2]) ? 0 : 1)' \
        "${HOME_DIR}/.agents/.skill-lock.json" "$1"; then
        __print_error "No lock entry named ${1}; personal skills are managed in home/.agents/skills"
        return 1
    fi
    __run_skills remove "$1" --global --yes
}
