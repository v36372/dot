function skill-add -d "Vendor upstream skills into the shared agents lock"
    if test (count $argv) -eq 0
        echo "Usage: skill-add <owner/repo|url|path> <skills-dir-path> [skill-name ...]" >&2
        echo "Example: skill-add cursor/plugins pstack/skills how" >&2
        return 2
    end

    switch $argv[1]
        case -h --help
            echo "Usage: skill-add <owner/repo|url|path> <skills-dir-path> [skill-name ...]"
            echo
            echo "Wraps ./dot add-skill. skills-dir-path filters which skill folders"
            echo "are considered; omit skill names to vendor every match."
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
