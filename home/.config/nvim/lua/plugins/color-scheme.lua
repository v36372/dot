return {
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("tokyonight").setup({
				style = "storm",
				transparent = true,
				-- Keep sidebars and floating windows opaque for readability.
				styles = {
					sidebars = "dark",
					floats = "dark",
				},
				plugins = {
					auto = true,
				},
			})

			vim.cmd.colorscheme("tokyonight-storm")

			local palette = require("tokyonight.colors").setup({ style = "storm" })

			-- Telescope highlights to match the editor background.
			vim.api.nvim_set_hl(0, "TelescopeNormal", { bg = palette.bg })
			vim.api.nvim_set_hl(0, "TelescopeBorder", { fg = palette.blue, bg = palette.bg })
			vim.api.nvim_set_hl(0, "TelescopePromptNormal", { bg = palette.bg })
			vim.api.nvim_set_hl(0, "TelescopePromptBorder", { fg = palette.blue, bg = palette.bg })
			vim.api.nvim_set_hl(0, "TelescopeResultsNormal", { bg = palette.bg })
			vim.api.nvim_set_hl(0, "TelescopeResultsBorder", { fg = palette.blue, bg = palette.bg })
			vim.api.nvim_set_hl(0, "TelescopePreviewNormal", { bg = palette.bg })
			vim.api.nvim_set_hl(0, "TelescopePreviewBorder", { fg = palette.blue, bg = palette.bg })
			vim.api.nvim_set_hl(0, "TelescopeTitle", { fg = palette.magenta, bg = palette.bg })
			vim.api.nvim_set_hl(0, "TelescopePromptTitle", { fg = palette.magenta, bg = palette.bg })
			vim.api.nvim_set_hl(0, "TelescopeResultsTitle", { fg = palette.magenta, bg = palette.bg })
			vim.api.nvim_set_hl(0, "TelescopePreviewTitle", { fg = palette.magenta, bg = palette.bg })

			-- Keep semantic highlights disabled to avoid noisy server-specific colors.
			for _, group in ipairs(vim.fn.getcompletion("@lsp", "highlight")) do
				vim.api.nvim_set_hl(0, group, {})
			end
		end,
	},
}
