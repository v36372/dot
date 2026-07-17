return {
	{
		"nvim-telescope/telescope.nvim",
		branch = "master",
		dependencies = {
			"nvim-lua/plenary.nvim",
			{
				"nvim-telescope/telescope-fzf-native.nvim",
				build = "cmake -S. -Bbuild -DCMAKE_BUILD_TYPE=Release && cmake --build build --config Release && cmake --install build --prefix build",
				cond = vim.fn.executable("cmake") == 1,
			},
		},
		config = function()
			local actions = require("telescope.actions")
			local telescope = require("telescope")

			telescope.setup({
				defaults = {
					mappings = {
						i = {
							["<C-k>"] = actions.move_selection_previous,
							["<C-j>"] = actions.move_selection_next,
							-- Send to quickfix
							["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
							-- Open search results in splits (your navigation workflow)
							["<C-v>"] = actions.select_vertical,
							["<C-c>"] = actions.select_horizontal,
							["<C-s>"] = actions.select_horizontal,
							["<C-t>"] = actions.select_tab,
							["<C-x>"] = actions.delete_buffer,
						},
						n = {
							["<C-v>"] = actions.select_vertical,
							["<C-c>"] = actions.select_horizontal,
							["s"] = actions.select_horizontal,
							["v"] = actions.select_vertical,
							["q"] = actions.close,
						},
					},
					file_ignore_patterns = {
						"node_modules",
						"yarn.lock",
						".git",
						".sl",
						"_build",
						".next",
						"%.lock",
					},
					hidden = true,
					path_display = {
						"filename_first",
					},
				},
			})

			pcall(telescope.load_extension, "fzf")
		end,
	},
}
