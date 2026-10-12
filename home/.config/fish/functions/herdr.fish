function herdr -d "Herdr CLI with machine short-name resolution"
    if test (count $argv) -ne 3; or test "$argv[1]" != machine; or not contains -- "$argv[2]" enable disable
        command herdr $argv
        return $status
    end

    set -l action $argv[2]
    set -l name $argv[3]
    set -l machines (command herdr machine list --json)
    or return $status

    set -l matches (printf '%s\n' "$machines" | jq -r --arg name "$name" '
        [.[] | select(
            (.id | ascii_downcase) == ($name | ascii_downcase) or
            (.target | ascii_downcase) == ($name | ascii_downcase) or
            (.label | ascii_downcase) == ($name | ascii_downcase)
        ) | .id] | unique[]
    ')
    or return $status

    if test (count $matches) -eq 0
        printf 'No saved Herdr machine matches "%s". Run `herdr machine list` to see available machines.\n' "$name" >&2
        return 1
    end
    if test (count $matches) -gt 1
        printf 'Machine name "%s" is ambiguous; use its full profile ID.\n' "$name" >&2
        return 1
    end

    command herdr machine $action $matches[1]
end
