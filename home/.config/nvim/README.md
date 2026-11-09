# Neovim

Copied from [craftzdog/dotfiles](https://github.com/craftzdog/dotfiles/tree/7c50fa72f64aada314c124cea005fd923e9f5c0f/dot_config/nvim).

All 23 upstream Lua files are unchanged except the personal namespace:
`craftzdog` → `v36372`, `Craftzdog` → `V36372`.
Plugin repository owners are unchanged.

Requires Neovim 0.12+, Git, a C compiler, tree-sitter CLI, Node.js, ripgrep,
fd, and a Nerd Font. Optional integrations use Fish and Lazygit.
Plugins use built-in `vim.pack`; Mason installs language tools.

```sh
./dot stow nvim
nvim --headless +MasonToolsInstallSync +qa
nvim --headless '+lua assert(vim.v.errmsg == "", vim.v.errmsg); assert(_G.V36372); assert(package.loaded["v36372.plugins.keymaps"]); print("NVIM_SETUP_OK")' +qa
```

Upstream bindings: `;f` files, `;r` grep, `sf` Oil explorer, `gd` definition,
`ss`/`sv` splits, `<Space>f` format. Theme: Solarized Osaka (transparent).
Copilot requires your own authentication via `:Copilot auth`.
