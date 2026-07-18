# Miniconda shell integration (if installed).
if test -x "$HOME/opt/miniconda3/bin/conda"
    "$HOME/opt/miniconda3/bin/conda" shell.fish hook $argv | source
end
