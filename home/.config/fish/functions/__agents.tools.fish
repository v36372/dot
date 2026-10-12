function __agents.tools -d "List coding agents configured globally in mise"
    if not command -q mise
        echo "error: mise is not on PATH" >&2
        return 127
    end

    set -l configured (command mise -C "$HOME" ls --global --current --no-header)
    or return $status

    for row in $configured
        set -l tool (string replace -r '\\s.*$' '' -- $row)
        switch $tool
            case claude claude-code codex copilot copilot-cli crush cursor-agent cursor-cli gemini gemini-cli grok oh-my-pi github:can1357/oh-my-pi opencode pi
                echo $tool
        end
    end
end
