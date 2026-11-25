#!/usr/bin/env bats
# Check the CLI/stow boundaries without contacting npm or GitHub.
setup() {
    load "../tests/test-helpers"
    load_dot_for_test
    command -v stow >/dev/null || skip "GNU Stow not installed"
    command -v node >/dev/null || skip "Node.js not installed"
    REPO="$DOT_TEST_TMP/repo"
    mkdir -p "$REPO/home/.agents/skills/personal" "$DOT_TEST_TMP/bin"
    cp -R "$DOT_ROOT" "$REPO/dot"
    DOT="$REPO/dot/bin/dot"
    LOCK="$REPO/home/.agents/.skill-lock.json"
    printf '{"version":3,"skills":{"example":{"source":"owner/repo"}}}\n' > "$LOCK"
    printf 'personal skill\n' > "$REPO/home/.agents/skills/personal/SKILL.md"
    export PATH="$DOT_TEST_TMP/bin:$PATH" XDG_STATE_HOME="$DOT_TEST_TMP/xdg"
    cat > "$DOT_TEST_TMP/bin/npx" <<'SH'
#!/bin/bash
set -euo pipefail
[[ -z "${XDG_STATE_HOME:-}" && "$1 $2" == '--yes skills@1.9.0' ]]
echo "$*" >> "$HOME/skills-calls"
case "$3" in
    add) mkdir -p "$HOME/.agents/skills/added"; touch "$HOME/.agents/skills/added/SKILL.md" ;;
    update)
        [[ "${SKIP_INSTALL:-}" != 1 ]] || exit 0
        mkdir -p "$HOME/.agents/skills/example"; touch "$HOME/.agents/skills/example/SKILL.md"
        ;;
    remove)
        rm "$HOME/.agents/skills/$4/SKILL.md"
        node -e 'const fs = require("node:fs"), [path, name] = process.argv.slice(1), lock = require(path); delete lock.skills[name]; fs.writeFileSync(path, JSON.stringify(lock));' "$HOME/.agents/.skill-lock.json" "$4"
        ;;
    *) exit 1 ;;
esac
SH
    chmod +x "$DOT_TEST_TMP/bin/npx"
}

teardown() {
    cleanup_dot_test
}

@test "stow keeps the skills directory real; sync restores and remove only touches locked skills" {
    run "$DOT" skills-sync
    [ "$status" -ne 0 ]
    [ ! -e "$HOME/skills-calls" ]

    run "$DOT" stow
    [ "$status" -eq 0 ]
    [ ! -L "$HOME/.agents/skills" ]
    [ -L "$HOME/.agents/skills/personal" ]
    [ "$HOME/.agents/.skill-lock.json" -ef "$LOCK" ]

    SKIP_INSTALL=1 run "$DOT" skills-sync
    [ "$status" -ne 0 ]
    [[ "$output" == *"Skill not installed: example"* ]]
    run "$DOT" skills-sync
    [ "$status" -eq 0 ]
    [ -f "$HOME/.agents/skills/example/SKILL.md" ]
    [ ! -e "$REPO/home/.agents/skills/example" ]

    run "$DOT" add-skill https://github.com/owner/repo/tree/main/skills/added
    [ "$status" -eq 0 ]
    [ -f "$HOME/.agents/skills/added/SKILL.md" ]
    grep -q 'add https://github.com/owner/repo/tree/main/skills/added --global --agent pi --yes$' "$HOME/skills-calls"

    run "$DOT" remove-skill personal
    [ "$status" -ne 0 ]
    [ -f "$HOME/.agents/skills/personal/SKILL.md" ]
    run "$DOT" remove-skill example
    [ "$status" -eq 0 ]
    [ ! -f "$HOME/.agents/skills/example/SKILL.md" ]
    ! grep -q example "$LOCK"
}

@test "a lock-only repo can restore third-party skills on a fresh home" {
    rm -r "$REPO/home/.agents/skills"
    run "$DOT" stow
    [ "$status" -eq 0 ]
    [ -d "$HOME/.agents/skills" ] && [ ! -L "$HOME/.agents/skills" ]
    run "$DOT" skills-sync
    [ "$status" -eq 0 ]
    [ -f "$HOME/.agents/skills/example/SKILL.md" ]
    [ ! -e "$REPO/home/.agents/skills" ]
}
