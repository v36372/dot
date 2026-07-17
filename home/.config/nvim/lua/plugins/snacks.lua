local filtered_message = { "No information available" }

return {
	{
		"folke/snacks.nvim",
		priority = 1000,
		lazy = false,

		---@type snacks.Config
		opts = {
			bigfile = { enabled = true },
			bufdelete = { enabled = true },
			dim = { enabled = true },
			-- File explorer (replaces neo-tree / oil)
			explorer = {
				enabled = true,
				replace_netrw = true,
			},
			gitbrowse = { enabled = true },
			indent = {
				enabled = true,
				indent = { only_scope = true },
				chunk = { enabled = true },
				animate = { enabled = false },
			},
			input = { enabled = true },
			notifier = {
				enabled = true,
				timeout = 3000,
				style = "fancy",
			},
			picker = {
				-- Used by Snacks.explorer under the hood
				sources = {
					explorer = {
						layout = { preset = "sidebar", preview = false },
						win = {
							list = {
								keys = {
									-- Open in splits (your neo-tree muscle memory)
									["<C-v>"] = { { "tcd", "edit_vsplit" }, mode = { "n", "i" } },
									["<C-c>"] = { { "tcd", "edit_split" }, mode = { "n", "i" } },
									["s"] = { { "tcd", "edit_split" }, mode = { "n" } },
									["v"] = { { "tcd", "edit_vsplit" }, mode = { "n" } },
								},
							},
						},
					},
				},
			},
			rename = { enabled = true },
			toggle = { enabled = true },
			scratch = { enabled = true },
			statuscolumn = { enabled = true },
			words = { enabled = true },
		},

		init = function()
			vim.api.nvim_create_autocmd("User", {
				pattern = "VeryLazy",
				callback = function()
					local notify = Snacks.notifier.notify
					---@diagnostic disable-next-line: duplicate-set-field
					Snacks.notifier.notify = function(message, level, opts)
						for _, msg in ipairs(filtered_message) do
							if message == msg then
								return nil
							end
						end
						return notify(message, level, opts)
					end
				end,
			})
		end,
		keys = {
			{
				"<leader>bd",
				function()
					Snacks.bufdelete()
				end,
				desc = "[B]uffer [D]elete",
			},
			{
				"<leader>bD",
				function()
					Snacks.bufdelete.other()
				end,
				desc = "Close all but the current buffer",
			},
			{
				"<leader>og",
				function()
					Snacks.gitbrowse()
				end,
				desc = "[O]pen [G]it",
				mode = { "n", "v" },
			},
			{
				"<leader>nh",
				function()
					Snacks.notifier.show_history()
				end,
				desc = "[N]otification [H]istory",
			},
			{
				"<leader>nd",
				function()
					Snacks.notifier.hide()
				end,
				desc = "[N]otifications [D]ismiss",
			},
			{
				"<leader>td",
				function()
					Snacks.toggle.diagnostics():toggle()
				end,
				desc = "[T]oggle [D]iagnostics",
			},
			{
				"<leader>zm",
				function()
					Snacks.toggle.dim():toggle()
				end,
				desc = "Toggle Dim Mode",
			},
			{
				"<leader>tw",
				function()
					Snacks.toggle.option("wrap"):toggle()
				end,
				desc = "[T]oggle line [W]rap",
			},
			{
				"<leader>tx",
				function()
					local tsc = require("treesitter-context")
					Snacks.toggle({
						name = "Treesitter Context",
						get = tsc.enabled,
						set = function(state)
							if state then
								tsc.enable()
							else
								tsc.disable()
							end
						end,
					}):toggle()
				end,
				desc = "Toggle [T]reesitter Conte[x]t",
			},
			{
				"<leader>ih",
				function()
					Snacks.toggle({
						name = "Inlay Hints",
						get = function()
							return vim.lsp.inlay_hint.is_enabled()
						end,
						set = function(state)
							if state then
								vim.lsp.inlay_hint.enable(true)
							else
								vim.lsp.inlay_hint.enable(false)
							end
						end,
					}):toggle()
				end,
				desc = "Toggle [I]nlay [H]ints",
			},
			{
				"<leader>hl",
				function()
					local hc = require("nvim-highlight-colors")
					Snacks.toggle({
						name = "Highlight Colors",
						get = function()
							return hc.is_active()
						end,
						set = function(state)
							if state then
								hc.turnOn()
							else
								hc.turnOff()
							end
						end,
					}):toggle()
				end,
				desc = "Toggle [H]igh[L]ight Colors",
			},
			{
				"<leader>.",
				function()
					Snacks.scratch()
				end,
				desc = "Toggle Scratch Buffer",
			},
			{
				"<leader>s.",
				function()
					Snacks.scratch.select()
				end,
				desc = "Search Scratch Buffers",
			},
		},
	},
}
