function agents-prune -d "Prune unused mise coding-agent versions, leaving runtimes alone"
    argparse --name=agents-prune 'n/dry-run' 'h/help' -- $argv
    or return $status

    if set -q _flag_help
        echo "Usage: agents-prune [--dry-run]"
        echo "Remove unused mise versions of globally configured coding agents only."
        echo "Versions referenced by tracked project configs are preserved."
        echo "Restart older running agent sessions before pruning their installation files."
        return 0
    end
    if set -q argv[1]
        echo "error: agents-prune does not take positional arguments" >&2
        return 2
    end

    set -l tools (__agents.tools)
    or return $status
    if not set -q tools[1]
        echo "error: no globally configured mise coding agents found" >&2
        return 1
    end

    set -l options --yes
    if set -q _flag_dry_run
        set -a options --dry-run
    end
    command mise -C "$HOME" prune --tools $options $tools
end
