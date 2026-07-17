# Promote fish to a system shell

User-local fish is already at `~/.local/bin/fish` and wired into ghostty/tmux/herdr/bashrc.

To make it the real login shell (optional):

```bash
# install package properly
sudo pacman -S fish

# allow as login shell
which fish | sudo tee -a /etc/shells

# set login shell
chsh -s "$(which fish)"
```

Until then, interactive bash execs fish via `~/.bashrc`, and ghostty/tmux/herdr start fish directly.
