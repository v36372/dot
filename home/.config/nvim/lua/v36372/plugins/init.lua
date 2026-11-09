gh = function(x)
	return "https://github.com/" .. x
end

vim.pack.add({
	-- UI
	{ src = gh("craftzdog/solarized-osaka.nvim") },
	{ src = gh("nvim-mini/mini.icons") },
	{ src = gh("folke/snacks.nvim") },
	{ src = gh("folke/trouble.nvim") },
	{ src = gh("nvim-lualine/lualine.nvim") },
	{ src = gh("b0o/incline.nvim") },
	{ src = gh("esmuellert/codediff.nvim") },
	{ src = gh("rachartier/tiny-cmdline.nvim") },
	-- Editor
	{ src = gh("stevearc/conform.nvim") },
	{ src = gh("nvim-treesitter/nvim-treesitter") },
	{ src = gh("mks-h/treesitter-autoinstall.nvim") },
	{ src = gh("nvim-mini/mini.pairs") },
	{ src = gh("craftzdog/mini.diff"), version = "feat/grouping" },
	{ src = gh("saghen/blink.cmp"), version = vim.version.range("^1") },
	{ src = gh("folke/todo-comments.nvim") },
	{ src = gh("lewis6991/gitsigns.nvim") },
	{ src = gh("linrongbin16/gitlinker.nvim") },
	{ src = gh("brenoprata10/nvim-highlight-colors") },
	-- LSP
	{ src = gh("neovim/nvim-lspconfig") },
	{ src = gh("mason-org/mason.nvim") },
	{ src = gh("WhoIsSethDaniel/mason-tool-installer.nvim") },
	-- Util
	{ src = gh("stevearc/oil.nvim") },
	{ src = gh("zbirenbaum/copilot.lua") },
})

if #vim.api.nvim_get_runtime_file("lua/v36372/plugins/local.lua", false) > 0 then
	require("v36372.plugins.local")
end

require("v36372.plugins.ui")
require("v36372.plugins.treesitter")
require("v36372.plugins.editor")
require("v36372.plugins.lsp")
require("v36372.plugins.util")
require("v36372.plugins.keymaps")
