# n / vim / vi open nvim (default to cwd)
function n -d "Open nvim (cwd if no args)"
    if test (count $argv) -eq 0
        command nvim .
    else
        command nvim $argv
    end
end

function vim -d "Open nvim (cwd if no args)"
    if test (count $argv) -eq 0
        command nvim .
    else
        command nvim $argv
    end
end

function vi -d "Open nvim (cwd if no args)"
    if test (count $argv) -eq 0
        command nvim .
    else
        command nvim $argv
    end
end

function fvim -d "Fuzzy-find a file and open in nvim"
    if test (count $argv) -eq 0
        fd -H -t f | fzf --header "Open File in Vim" --preview "bat --style=numbers --color=always {} 2>/dev/null || cat {}" | xargs -r nvim
    else
        set -l query (string join " " $argv)
        fd -H -t f | fzf --header "Open File in Vim" --preview "bat --style=numbers --color=always {} 2>/dev/null || cat {}" -q "$query" | xargs -r nvim
    end
end

# macOS already provides /usr/bin/open; define this helper only on Linux.
if command -q xdg-open
    function open -d "Open path with xdg-open"
        xdg-open $argv >/dev/null 2>&1 &
    end
end

function eff -d "Edit file chosen via fzf"
    set -l file (ff)
    and test -n "$file"
    and $EDITOR $file
end
