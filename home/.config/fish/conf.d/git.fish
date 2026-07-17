# Load oh-my-zsh style git abbreviations from __git.init
if test -f $__fish_config_dir/functions/__git.init.fish
    source $__fish_config_dir/functions/__git.init.fish
    __git.init
end
