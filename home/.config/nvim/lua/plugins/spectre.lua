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
			local theme = require("tokyonight.colors").setup({ style = "storm" })

			vim.api.nvim_set_hl(0, "SpectreSearch", { bg = theme.red, fg = theme.black })
			vim.api.nvim_set_hl(0, "SpectreReplace", { bg = theme.green, fg = theme.black })

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
				-- replace_engine = {
				-- 	sed = {
				-- 		cmd = "sed",
				-- 		args = {
				-- 			"-i",
				-- 			"",
				-- 			"-E",
				-- 		},
				-- 	},
				-- },
			})
		end,
	},
}
