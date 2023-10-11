# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$HOME/.cargo/bin:$PATH
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/go/bin:/usr/local/mysql/bin:/Users/tintnguyen/.fzf/bin:/Users/v36372/go/bin:/Users/v36372/Library/Python/2.7/bin
alias python3=/usr/local/opt/python@3.10/bin/python3
alias t="todo.sh"
alias ta=AddNewTaskWithPriC
alias tl="todo.sh listall"
alias td="todo.sh do"
alias tr="todo.sh report"
alias tp="todo.sh pri"
alias tdel="todo.sh -f del"

alias vim="nvim -u ~/.config/vim/init.lua"

function AddNewTaskWithPriC()
{
  todo.sh -tAf add "$1" | head -1 | awk '{print $1}' | xargs -t -I {} todo.sh pri {} C
}

setopt PROMPT_SUBST
PROMPT='%F{red}%n%f:${(%):-%~} '

HISTFILE="$HOME/.zsh_history"
HISTsIZE=10000000
SAVEHIST=10000000
setopt inc_append_history
setopt hist_ignore_dups
setopt hist_ignore_space
setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt HIST_EXPIRE_DUPS_FIRST
setopt EXTENDED_HISTORY          # Write the history file in the ":start:elapsed;command" format.
setopt HIST_IGNORE_ALL_DUPS      # Delete old recorded entry if new entry is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a line previously found.
setopt HIST_IGNORE_SPACE         # Don't record an entry starting with a space.
setopt HIST_SAVE_NO_DUPS         # Don't write duplicate entries in the history file.
setopt HIST_REDUCE_BLANKS        # Remove superfluous blanks before recording entry.
setopt HIST_VERIFY               # Don't execute immediately upon history expansion.
setopt HIST_BEEP

# FZF
source $HOME/.fzf.zsh

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export PATH="/usr/local/opt/python@3.10/bin:$PATH"
. $HOME/.cargo/env

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/v36372/Downloads/google-cloud-sdk/path.zsh.inc' ]; then . '/Users/v36372/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/v36372/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then . '/Users/v36372/Downloads/google-cloud-sdk/completion.zsh.inc'; fi

export GOTESTS_TEMPLATE=testify

autoload -U +X bashcompinit && bashcompinit
complete -o nospace -C /usr/local/bin/terraform terraform
