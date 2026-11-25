function skill-add -d "Install and lock an upstream skill from GitHub"
    if test (count $argv) -eq 0
        echo "Usage: skill-add <github-skill-url>" >&2
        echo "Example: skill-add https://github.com/owner/repo/tree/main/path/to/skill" >&2
        return 2
    end

    switch $argv[1]
        case -h --help
            echo "Usage: skill-add <github-skill-url>"
            echo
            echo "Wraps 'dot add-skill'. Pass a GitHub tree URL of the skill directory"
            echo "(the folder that contains SKILL.md), or a blob URL of SKILL.md."
            return 0
    end

    if not command -q dot
        echo "error: dot not found on PATH" >&2
        return 127
    end

    command dot add-skill $argv
end
