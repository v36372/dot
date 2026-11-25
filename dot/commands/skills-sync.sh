cmd_skills_sync_usage() {
    printf 'USAGE:\n    %s skills-sync\n\nRestore missing and update installed skills from the stowed global lock.\n' "$SCRIPT_NAME"
}

cmd_skills_sync() {
    __require_no_args skills-sync "$@" || return 1
    __acquire_run_lock && __require_skills_home || return 1
    __run_skills update --global --yes || return 1
    node -e '
        const { existsSync } = require("node:fs");
        const lock = require(process.argv[1]);
        for (const name of Object.keys(lock.skills)) {
            if (existsSync(`${process.env.HOME}/.agents/skills/${name}/SKILL.md`)) continue;
            console.error(`Skill not installed: ${name}`);
            process.exitCode = 1;
        }
    ' "${HOME_DIR}/.agents/.skill-lock.json"
}
