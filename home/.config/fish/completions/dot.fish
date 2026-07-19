# Completions for personal dot helper
complete -c dot -f
complete -c dot -n __fish_use_subcommand -a stow -d "Create/update symlinks"
complete -c dot -n __fish_use_subcommand -a restow -d "Re-stow symlinks"
complete -c dot -n __fish_use_subcommand -a unstow -d "Remove managed symlinks"
complete -c dot -n __fish_use_subcommand -a skills-sync -d "Update locked third-party skills"
complete -c dot -n __fish_use_subcommand -a doctor -d "Check tools and symlink health"
complete -c dot -n __fish_use_subcommand -a path -d "Print repo path"
complete -c dot -n __fish_use_subcommand -a help -d "Show help"
