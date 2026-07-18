function __pi.commit -d "Commit with pi" -a mode
    set -l guidance (string join " " $argv[2..-1])

    command git rev-parse --is-inside-work-tree >/dev/null 2>&1
    or begin
        echo "Not in a git repo"
        return 1
    end

    if test "$mode" = all
        command git add -A; or return
        if command git diff --cached --quiet
            echo "Nothing to commit"
            return 1
        end
        set prompt "Commit all current changes, including newly added files."
    else
        command git reset --quiet; or return
        command git add -u; or return
        if command git diff --cached --quiet
            echo "No tracked changes to commit"
            return 1
        end
        set prompt "Commit only tracked changes. Do not include untracked files."
    end

    if test -n "$guidance"
        set prompt "$prompt $guidance"
    end

    pi -p \
        --no-extensions \
        --no-skills \
        --no-prompt-templates \
        --no-themes \
        --no-context-files \
        --model "openai-codex/gpt-5.4-mini:off" \
        --skill "$PI_COMMIT_SKILL" \
        "/skill:commit $prompt" \
        </dev/null
end
