return {
	{
		"folke/tokyonight.nvim",
		lazy = false,
		priority = 1000,
		config = function()
			require("tokyonight").setup({
				style = "storm",
				transparent = true,
				terminal_colors = true,
				styles = {
					sidebars = "transparent",
					floats = "transparent",
				},
				plugins = {
					auto = true,
				},
				on_highlights = function(hl, c)
					-- Extra chrome that still paints solid with transparent=true.
					hl.StatusLine = { fg = c.fg_sidebar, bg = c.none }
					hl.StatusLineNC = { fg = c.fg_gutter, bg = c.none }
					hl.Pmenu = { fg = c.fg, bg = c.none }
					hl.PmenuSbar = { bg = c.none }
					hl.PmenuThumb = { bg = c.fg_gutter }
					hl.FloatBorder = { fg = c.border_highlight, bg = c.none }
					hl.FloatTitle = { fg = c.magenta, bg = c.none }

					-- Telescope.
					hl.TelescopeNormal = { fg = c.fg, bg = c.none }
					hl.TelescopeBorder = { fg = c.blue, bg = c.none }
					hl.TelescopePromptNormal = { bg = c.none }
					hl.TelescopePromptBorder = { fg = c.blue, bg = c.none }
					hl.TelescopeResultsNormal = { bg = c.none }
					hl.TelescopeResultsBorder = { fg = c.blue, bg = c.none }
					hl.TelescopePreviewNormal = { bg = c.none }
					hl.TelescopePreviewBorder = { fg = c.blue, bg = c.none }
					hl.TelescopeTitle = { fg = c.magenta, bg = c.none }
					hl.TelescopePromptTitle = { fg = c.magenta, bg = c.none }
					hl.TelescopeResultsTitle = { fg = c.magenta, bg = c.none }
					hl.TelescopePreviewTitle = { fg = c.magenta, bg = c.none }
				end,
			})

			vim.cmd.colorscheme("tokyonight-storm")
		end,
	},
}
