return {
	{
		"nvim-pack/nvim-spectre",
		lazy = true,
		cmd = { "Spectre" },
		dependencies = {
			"nvim-lua/plenary.nvim",
			"folke/tokyonight.nvim",
		},
		config = function()
			local colors = require("tokyonight.colors").setup({ style = "storm" })

			vim.api.nvim_set_hl(0, "SpectreSearch", { bg = colors.red, fg = colors.bg })
			vim.api.nvim_set_hl(0, "SpectreReplace", { bg = colors.green, fg = colors.bg })

			require("spectre").setup({
				highlight = {
					search = "SpectreSearch",
					replace = "SpectreReplace",
				},
				mapping = {
					["send_to_qf"] = {
						map = "<C-q>",
						cmd = "<cmd>lua require('spectre.actions').send_to_qf()<CR>",
						desc = "send all items to quickfix",
					},
				},
			})
		end,
	},
}
