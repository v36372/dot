# NEOVIM CONFIG

Lua-based, lazy.nvim managed. Style from dmmulroy, keymaps personal.

## STRUCTURE

```
nvim/
├── init.lua                 # require("config")
├── lua/config/
│   ├── init.lua             # orchestrates requires
│   ├── options.lua
│   ├── keymaps.lua          # ALL keybindings + map_lsp_keybinds
│   ├── lazy.lua
│   ├── prelude.lua          # helpers (open_link, split+lsp, diagnostics copy)
│   └── ...
└── lua/plugins/             # 1 file per plugin
```

## WHERE TO LOOK

| Task | Location |
|------|----------|
| Add plugin | `lua/plugins/<name>.lua` |
| Add keymap | `lua/config/keymaps.lua` |
| Change option | `lua/config/options.lua` |
| LSP server | `lua/plugins/lsp.lua` → `servers` table |
| Formatter | `lua/plugins/conform.lua` |
| Completion | `lua/plugins/blink-cmp.lua` |
| Explorer | `lua/plugins/snacks.lua` (`explorer` opts) |
| Fuzzy | `lua/plugins/telescope.lua` |

## CONVENTIONS

- Plugin files return `{ ... }` lazy.nvim spec
- LSP: nvim 0.11+ `vim.lsp.config()` + `vim.lsp.enable()`
- Keymaps via `LspAttach` → `config.keymaps.map_lsp_keybinds`
- Auto-center nav with `zz` where useful
- Completion: blink.cmp

## ANTI-PATTERNS

- neo-tree / oil as primary explorer (use Snacks explorer)
- nvim-cmp (use blink.cmp)
- Hardcoding colorscheme outside `color-scheme.lua`

## NAVIGATION KEYMAPS (DO NOT REGRESS)

These are the owner's primary workflow:

| Key | Action |
|-----|--------|
| `<C-p>` | Find files |
| `<leader>ss` | Project live grep |
| `<leader>sw` | Grep cword |
| `<C-f>` | Buffer fuzzy |
| `<leader>e` / `<leader>fp` | Explorer reveal current file |
| `gd` | Go to definition |
| `<C-o>` / `<C-i>` | Jump list back/forward |
| `<leader>gd` | Definition in vsplit |
| `<leader>gD` | Definition in hsplit |
| `<C-v>` (n) | Vsplit + tag jump |
| Telescope `<C-v>` / `<C-c>` | Open result vsplit / hsplit |
| Explorer `v`/`s` | Open file vsplit / hsplit |
| `gr` / `gi` | References / implementations |
| `<C-w>` / `<C-q>` | Save / save+quit |
| `jj` | Insert → normal |
