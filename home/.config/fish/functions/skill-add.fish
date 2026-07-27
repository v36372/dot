function skill-add -d "Vendor one upstream skill from a GitHub skill-dir URL"
    if test (count $argv) -eq 0
        echo "Usage: skill-add <github-skill-url>" >&2
        echo "Example: skill-add https://github.com/owner/repo/tree/main/path/to/skill" >&2
        return 2
    end

    switch $argv[1]
        case -h --help
            echo "Usage: skill-add <github-skill-url>"
            echo
            echo "Wraps ./dot add-skill. Pass a GitHub tree URL of the skill directory"
            echo "(the folder that contains SKILL.md), or a blob URL of SKILL.md."
            return 0
    end

    if not command -q dot
        echo "error: dot not found on PATH" >&2
        return 127
    end

    set -l dotfiles_root (dot path 2>/dev/null)
    or begin
        echo "error: could not resolve dotfiles path" >&2
        return 1
    end

    "$dotfiles_root/dot" add-skill $argv
end
