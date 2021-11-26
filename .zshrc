# If you come from bash you might have to change your $PATH.
export PATH=$HOME/bin:/usr/local/bin:$PATH
export CLICOLOR=1
export LSCOLORS=GxFxCxDxBxegedabagaced
export PATH=/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/go/bin:/usr/local/mysql/bin:/Users/tintnguyen/.fzf/bin

setopt PROMPT_SUBST
PROMPT='${(%):-%~} '

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



# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/Users/tintnguyen/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
else
    if [ -f "/Users/tintnguyen/miniconda3/etc/profile.d/conda.sh" ]; then
        . "/Users/tintnguyen/miniconda3/etc/profile.d/conda.sh"
    else
        export PATH="/Users/tintnguyen/miniconda3/bin:$PATH"
    fi
fi
unset __conda_setup
# <<< conda initialize <<<

