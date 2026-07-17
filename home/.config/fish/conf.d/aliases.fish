# Clear / editor
alias c 'clear'
alias vimdiff 'nvim -d'
alias v 'nvim'
alias p 'pi'
alias op 'opencode --port'
alias lg 'lazygit'
alias ld 'lazydocker'

# Grep color
alias grep 'grep --color=auto --exclude-dir={.bzr,CVS,.git,.hg,.svn,.idea,.tox}'

# Clipboard (Wayland)
if command -q wl-copy
    alias pbc 'wl-copy'
    alias pbp 'wl-paste'
else if command -q xclip
    alias pbc 'xclip -selection clipboard'
    alias pbp 'xclip -selection clipboard -o'
end

# eza (Omarchy style)
if command -q eza
    alias ls 'eza -lh --group-directories-first --icons=auto'
    alias lsa 'ls -a'
    alias ll 'eza -lah --group-directories-first --icons=auto'
    alias lt 'eza --tree --level=2 --long --icons --git'
    alias lta 'lt -a'
else
    alias ll 'ls -lah'
end

# Directories
alias .. 'cd ..'
alias ... 'cd ../..'
alias .... 'cd ../../..'

# Tools
alias d 'docker'
alias t 'tmux attach || tmux new -s Work'
alias g 'git'
alias gcm 'git commit -m'
alias gcam 'git commit -a -m'
alias gcad 'git commit -a --amend'
alias gs 'git status'
alias gd 'git diff'
alias gl 'git l'

# fzf preview helpers
if command -q bat
    alias ff "fzf --preview 'bat --style=numbers --color=always {}'"
else
    alias ff 'fzf'
end
