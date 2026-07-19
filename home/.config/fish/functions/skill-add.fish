function skill-add -d "Add upstream skills to the shared lock"
    if test (count $argv) -eq 0
        echo "Usage: skill-add <owner/repo|url|path> [skill-name ...]" >&2
        echo "Example: skill-add mattpocock/skills code-review" >&2
        return 2
    end

    switch $argv[1]
        case -h --help
            echo "Usage: skill-add <owner/repo|url|path> [skill-name ...]"
            echo
            echo "With skill names, installs them non-interactively."
            echo "Without skill names, opens the skills CLI selector."
            return 0
    end

    set -l source $argv[1]
    set -e argv[1]
    set -l npm_cache "$HOME/.cache/npm"
    mkdir -p "$npm_cache"

    set -l skills_command npx --yes skills@latest add "$source" --global --agent cline
    if test (count $argv) -gt 0
        set -a skills_command --skill $argv --yes
    end

    env NPM_CONFIG_CACHE="$npm_cache" $skills_command
    or return $status

    echo
    echo "Added to ~/.agents/skills and ~/.agents/.skill-lock.json"
    if command -q dot
        set -l dotfiles_root (dot path 2>/dev/null)
        if test $status -eq 0
            printf 'Review: git -C "%s" diff -- home/.agents\n' "$dotfiles_root"
        end
    end
end
