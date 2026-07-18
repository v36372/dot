-- Enable relative line numbers
vim.opt.nu = true
vim.opt.rnu = true

-- Disable showing the mode below the statusline
vim.opt.showmode = false

-- Set tabs to 2 spaces
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true

-- Enable auto indenting and set it to spaces
vim.opt.smartindent = true
vim.opt.shiftwidth = 2

-- Enable smart indenting
vim.opt.breakindent = true

-- Enable incremental searching
vim.opt.incsearch = true
vim.opt.hlsearch = true

-- Disable text wrap
vim.opt.wrap = false

-- Set leader key to space
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- Disable built-in ftplugin maps so treesitter textobject motions are not shadowed
vim.g.no_plugin_maps = true

-- Better splitting
vim.opt.splitbelow = true
vim.opt.splitright = true

-- Enable mouse mode
vim.opt.mouse = "a"

-- Enable ignorecase + smartcase for better searching
vim.opt.ignorecase = true
vim.opt.smartcase = true

-- Decrease updatetime to 250ms
vim.opt.updatetime = 250

-- Set completeopt to have a better completion experience
vim.opt.completeopt = { "menu", "menuone", "noselect" }

-- Enable persistent undo history
vim.opt.undofile = true

-- Enable 24-bit color
vim.opt.termguicolors = true

-- Enable the sign column to prevent the screen from jumping
vim.opt.signcolumn = "yes"

-- Enable access to System Clipboard
vim.opt.clipboard = "unnamed,unnamedplus"

-- Enable cursor line highlight
vim.opt.cursorline = true

-- Fold settings (nvim-ufo compatible)
vim.opt.foldcolumn = "0"
vim.opt.foldenable = true
vim.opt.foldlevel = 99
vim.opt.foldlevelstart = 99
vim.opt.foldnestmax = 5
vim.opt.foldtext = ""

-- Always keep 8 lines above/below cursor unless at start/end of file
vim.opt.scrolloff = 8

-- Place a column line
vim.opt.colorcolumn = "80"

vim.opt.guicursor = {
	"n-v-c:block",
	"i-ci-ve:ver25",
	"r-cr:hor20",
	"o:hor50",
	"a:blinkwait700-blinkoff400-blinkon250",
	"sm:block-blinkwait175-blinkoff150-blinkon175",
}

-- Treesitter indent + highlighting bootstrap
local treesitter_indent_disabled_filetypes = {
	ocaml = true,
	["ocaml.interface"] = true,
}

local treesitter_group = vim.api.nvim_create_augroup("config-treesitter-main", { clear = true })

vim.api.nvim_create_autocmd("FileType", {
	group = treesitter_group,
	callback = function(args)
		local has_parser = pcall(vim.treesitter.start, args.buf)
		if not has_parser then
			return
		end

		local filetype = vim.bo[args.buf].filetype
		if treesitter_indent_disabled_filetypes[filetype] then
			return
		end

		local language = vim.treesitter.language.get_lang(filetype)
		if not language then
			return
		end

		local has_indents, query = pcall(vim.treesitter.query.get, language, "indents")
		if has_indents and query then
			vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
		end
	end,
})
