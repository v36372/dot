return {
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v3.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"MunifTanjim/nui.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		cmd = "Neotree",
		opts = {
			close_if_last_window = true,
			filesystem = {
				bind_to_cwd = false,
				follow_current_file = { enabled = true },
				filtered_items = {
					visible = true,
					hide_dotfiles = false,
					hide_gitignored = false,
				},
				use_libuv_file_watcher = true,
			},
			window = {
				position = "left",
				width = 35,
				mappings = {
					["<C-v>"] = "open_vsplit",
					["<C-c>"] = "open_split",
					["s"] = "open_split",
					["v"] = "open_vsplit",
				},
			},
		},
	},
}
