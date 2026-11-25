# Use the same global lock format as the skills CLI. Stow links the lock, not
# the installed third-party files; personal skill folders are stowed as usual.
__require_skills_home() {
    if [[ ! -f "${HOME}/.agents/.skill-lock.json" ||
          ! "${HOME}/.agents/.skill-lock.json" -ef "${HOME_DIR}/.agents/.skill-lock.json" ||
          -L "${HOME}/.agents" || -L "${HOME}/.agents/skills" || ! -d "${HOME}/.agents/skills" ]]; then
        __print_error "Skills need a stowed lock file and real ~/.agents/skills directory; run '${SCRIPT_NAME} stow' first"
        return 1
    fi
    if ! __command_exists node || ! __command_exists npx; then
        __print_error "npx is required (install Node.js 22.20 or later)"
        return 1
    fi
}

__run_skills() (
    # Force the CLI to use the stowed global lock even if XDG_STATE_HOME is set.
    unset XDG_STATE_HOME
    DISABLE_TELEMETRY=1 npx --yes skills@1.9.0 "$@"
)
