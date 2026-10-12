function agents-upgrade -d "Upgrade mise coding agents, bypassing minimum release age"
    argparse --name=agents-upgrade 'n/dry-run' 'h/help' -- $argv
    or return $status

    if set -q _flag_help
        echo "Usage: agents-upgrade [--dry-run] (shortcut: aiup)"
        echo "Upgrade globally configured coding agents; leave Node, Go and project configs alone."
        echo "Fetch fresh versions and bypass release-age limits for this invocation only."
        echo "Old mise versions are retained; use agents-prune to remove unused ones."
        return 0
    end
    if set -q argv[1]
        echo "error: agents-upgrade does not take positional arguments" >&2
        return 2
    end

    set -lx MISE_MINIMUM_RELEASE_AGE 0
    set -lx MISE_FETCH_REMOTE_VERSIONS_CACHE 0s
    set -l tools (__agents.tools)
    or return $status
    if not set -q tools[1]
        echo "error: no globally configured mise coding agents found" >&2
        return 1
    end

    set -l options --no-prune
    if set -q _flag_dry_run
        set -a options --dry-run
    end
    command mise -C "$HOME" upgrade --minimum-release-age 0 $options $tools
end
