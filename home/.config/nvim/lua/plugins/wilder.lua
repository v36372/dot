return {
	{
		"gelguy/wilder.nvim",
		keys = {
			":",
			"/",
			"?",
		},
		dependencies = {
			"folke/tokyonight.nvim",
		},
		config = function()
			local wilder = require("wilder")
			local colors = require("tokyonight.colors").setup({ style = "storm" })

			-- Create highlight groups for the popup menu.
			local text_highlight =
				wilder.make_hl("WilderText", { { a = 1 }, { a = 1 }, { foreground = colors.fg } })
			local accent_highlight =
				wilder.make_hl("WilderAccent", { { a = 1 }, { a = 1 }, { foreground = colors.magenta } })

			-- Enable wilder when pressing :, / or ?
			wilder.setup({ modes = { ":", "/", "?" } })

			-- Avoid Python remote-plugin filters (needs pynvim + UpdateRemotePlugins).
			-- Without that, fuzzy cmdline matching throws:
			--   E117: Unknown function: _wilder_python_fuzzy_filt
			wilder.set_option("use_python_remote_plugin", false)

			-- Enable fuzzy matching for commands and buffers (pure Vim)
			wilder.set_option("pipeline", {
				wilder.branch(
					wilder.cmdline_pipeline({
						fuzzy = 1,
						language = "vim",
					}),
					wilder.vim_search_pipeline()
				),
			})

			wilder.set_option(
				"renderer",
				wilder.popupmenu_renderer(wilder.popupmenu_border_theme({
					highlighter = wilder.basic_highlighter(),
					highlights = {
						default = text_highlight,
						border = accent_highlight,
						accent = accent_highlight,
					},
					pumblend = 5,
					min_width = "100%",
					min_height = "25%",
					max_height = "25%",
					border = "rounded",
					left = { " ", wilder.popupmenu_devicons() },
					right = { " ", wilder.popupmenu_scrollbar() },
				}))
			)
		end,
	},
}
