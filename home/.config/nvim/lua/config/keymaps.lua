local prelude = require("config.prelude")
local copy_line_diagnostics_to_clipboard = prelude.copy_line_diagnostics_to_clipboard
local open_link = prelude.open_link
local open_lsp_in_split = prelude.open_lsp_in_split

local M = {}

-- ---------------------------------------------------------------------------
-- Leader / basics
-- ---------------------------------------------------------------------------
vim.keymap.set("n", "<space>", "<nop>", { desc = "Disable space (leader) in normal mode" })
vim.keymap.set("v", "<space>", "<nop>", { desc = "Disable space (leader) in visual mode" })

-- Save / quit (your muscle memory)
vim.keymap.set({ "i", "v", "n", "s" }, "<C-w>", "<cmd>w<cr><esc>", { desc = "Save file" })
vim.keymap.set({ "i", "v", "n", "s" }, "<C-q>", "<cmd>wq<cr><esc>", { desc = "Save and quit" })
vim.keymap.set("n", "<leader>w", "<cmd>w<cr>", { silent = false, desc = "Save current buffer" })
vim.keymap.set("n", "<leader>q", "<cmd>q<cr>", { silent = false, desc = "Quit current buffer" })

-- Insert escape
vim.keymap.set("i", "jj", "<esc>", { desc = "Exit insert mode (jj)" })
vim.keymap.set("i", "JJ", "<esc>", { desc = "Exit insert mode (JJ)" })

-- Clear search highlight
vim.keymap.set({ "i", "n" }, "<esc>", "<cmd>noh<cr><esc>", { desc = "Clear hlsearch and ESC" })
vim.keymap.set("n", "<leader>no", "<cmd>noh<cr>", { desc = "Toggle search highlighting" })

-- Swap between last two buffers
vim.keymap.set("n", "<leader>'", "<C-^>", { desc = "Switch to last buffer" })
vim.keymap.set("n", "<leader><tab>", "<cmd>b#<cr>", { desc = "Previously opened buffer" })

-- Buffers
vim.keymap.set("n", "<tab>", "<cmd>bnext<cr>", { desc = "Next buffer" })
vim.keymap.set("n", "<S-tab>", "<cmd>bprevious<cr>", { desc = "Prev buffer" })

-- ---------------------------------------------------------------------------
-- Navigation centering (dmmulroy style)
-- ---------------------------------------------------------------------------
vim.keymap.set("n", "<C-u>", "<C-u>zz", { desc = "Scroll up and center" })
vim.keymap.set("n", "<C-d>", "<C-d>zz", { desc = "Scroll down and center" })
vim.keymap.set("n", "{", "{zz", { desc = "Jump to previous paragraph and center" })
vim.keymap.set("n", "}", "}zz", { desc = "Jump to next paragraph and center" })
vim.keymap.set("n", "N", "Nzz", { desc = "Search previous and center" })
vim.keymap.set("n", "n", "nzz", { desc = "Search next and center" })
vim.keymap.set("n", "G", "Gzz", { desc = "Go to end of file and center" })
vim.keymap.set("n", "gg", "ggzz", { desc = "Go to beginning of file and center" })
vim.keymap.set("n", "<C-i>", "<C-i>zz", { desc = "Jump forward in jump list and center" })
vim.keymap.set("n", "<C-o>", "<C-o>zz", { desc = "Jump backward in jump list and center" })
vim.keymap.set("n", "%", "%zz", { desc = "Jump to matching bracket and center" })
vim.keymap.set("n", "*", "*zz", { desc = "Search for word under cursor and center" })
vim.keymap.set("n", "#", "#zz", { desc = "Search backward for word under cursor and center" })

-- Jump to start/end of line
vim.keymap.set({ "n", "v" }, "L", "$", { desc = "Jump to end of line" })
vim.keymap.set({ "n", "v" }, "H", "^", { desc = "Jump to beginning of line" })
vim.keymap.set("v", "L", "$<left>", { desc = "Move to end of line in visual mode" })

-- Redo
vim.keymap.set("n", "U", "<C-r>", { desc = "Redo last change" })

-- Visual line wraps
vim.keymap.set("n", "k", "v:count == 0 ? 'gk' : 'k'", { expr = true })
vim.keymap.set("n", "j", "v:count == 0 ? 'gj' : 'j'", { expr = true })

-- Better indenting
vim.keymap.set("v", "<", "<gv")
vim.keymap.set("v", ">", ">gv")
vim.keymap.set("x", "<<", function()
	vim.cmd("normal! <<")
	vim.cmd("normal! gv")
end, { desc = "Indent left and reselect" })
vim.keymap.set("x", ">>", function()
	vim.cmd("normal! >>")
	vim.cmd("normal! gv")
end, { desc = "Indent right and reselect" })

-- Paste without yanking
vim.keymap.set("v", "p", '"_dp')
vim.keymap.set("v", "P", '"_dP')
vim.keymap.set("x", "<leader>p", '"_dP', { desc = "Paste without overwriting register" })

-- Move visual block
vim.keymap.set("v", "<A-j>", ":m '>+1<CR>gv=gv", { desc = "Move selected block down" })
vim.keymap.set("v", "<A-k>", ":m '<-2<CR>gv=gv", { desc = "Move selected block up" })

-- Fold
vim.keymap.set("n", "<C-c>", "za", { desc = "Toggle fold" })

-- ---------------------------------------------------------------------------
-- File explorer (Snacks explorer — replaces neo-tree)
-- Open current file's directory / reveal current file
-- ---------------------------------------------------------------------------
vim.keymap.set("n", "<leader>e", function()
	Snacks.explorer({ reveal = true })
end, { desc = "Explorer: reveal current file" })

vim.keymap.set("n", "<leader>fp", function()
	Snacks.explorer({ reveal = true })
end, { desc = "Explorer: reveal current file" })

vim.keymap.set("n", "<leader>E", function()
	Snacks.explorer()
end, { desc = "Explorer: project root" })

-- ---------------------------------------------------------------------------
-- Search (your hotkeys, Telescope backend)
-- ---------------------------------------------------------------------------
-- <C-p> find files (your muscle memory)
vim.keymap.set("n", "<C-p>", function()
	require("telescope.builtin").find_files({ hidden = true })
end, { desc = "Find files" })

-- Project string search
vim.keymap.set("n", "<leader>ss", function()
	require("telescope.builtin").live_grep()
end, { desc = "Search string in project" })

-- Word under cursor (project-wide)
vim.keymap.set("n", "<leader>sw", function()
	require("telescope.builtin").grep_string()
end, { desc = "Search word under cursor" })

-- Search in current buffer
vim.keymap.set("n", "<C-f>", function()
	require("telescope.builtin").current_buffer_fuzzy_find(
		require("telescope.themes").get_dropdown({ previewer = false })
	)
end, { desc = "Search in current buffer" })

vim.keymap.set("n", "<leader>/", function()
	require("telescope.builtin").current_buffer_fuzzy_find(
		require("telescope.themes").get_dropdown({ previewer = false })
	)
end, { desc = "Fuzzily search in current buffer" })

vim.keymap.set("n", "<leader>sf", function()
	require("telescope.builtin").find_files({ hidden = true })
end, { desc = "Find files" })

vim.keymap.set("n", "<leader>sg", function()
	require("telescope.builtin").live_grep()
end, { desc = "Live grep" })

vim.keymap.set("n", "<leader>sb", function()
	require("telescope.builtin").buffers()
end, { desc = "Search open buffers" })

vim.keymap.set("n", "<leader>bb", function()
	require("telescope.builtin").buffers()
end, { desc = "List buffers" })

vim.keymap.set("n", "<leader>fr", function()
	require("telescope.builtin").oldfiles()
end, { desc = "Recent files" })

vim.keymap.set("n", "<leader>?", function()
	require("telescope.builtin").oldfiles()
end, { desc = "Find recently opened files" })

vim.keymap.set("n", "<leader>sh", function()
	require("telescope.builtin").help_tags()
end, { desc = "Search help tags" })

vim.keymap.set("n", "<leader>sc", function()
	require("telescope.builtin").git_bcommits()
end, { desc = "Search buffer commits" })

vim.keymap.set("n", "<leader>sR", function()
	require("telescope.builtin").resume()
end, { desc = "Resume last search" })

-- Quick find/replace word under cursor (buffer)
vim.keymap.set("n", "S", function()
	local cmd = ":%s/<C-r><C-w>/<C-r><C-w>/gI<Left><Left><Left>"
	local keys = vim.api.nvim_replace_termcodes(cmd, true, false, true)
	vim.api.nvim_feedkeys(keys, "n", false)
end, { desc = "Quick find/replace word under cursor" })

vim.keymap.set("n", "<leader>sr", ":%s/", { desc = "Buffer search and replace" })

-- Spectre for global find/replace
vim.keymap.set("n", "<leader>S", function()
	require("spectre").toggle()
end, { desc = "Toggle Spectre for global find/replace" })

-- ---------------------------------------------------------------------------
-- Windows / splits (your navigation muscle memory)
-- ---------------------------------------------------------------------------
-- Open definition-style jump in vsplit (your <C-v> habit)
vim.keymap.set("n", "<C-v>", "<cmd>vsplit<cr><C-]><cr>", { desc = "Vsplit + tag jump" })

vim.keymap.set("n", "<leader>ws", "<cmd>split<cr>", { desc = "Horizontal split" })
vim.keymap.set("n", "<leader>wv", "<cmd>vsplit<cr>", { desc = "Vertical split" })
vim.keymap.set("n", "<leader>wc", "<cmd>close<cr>", { desc = "Close window" })
vim.keymap.set("n", "<leader>wT", "<cmd>wincmd T<cr>", { desc = "Move window to new tab" })
vim.keymap.set("n", "<leader>wr", "<cmd>wincmd r<cr>", { desc = "Rotate down/right" })
vim.keymap.set("n", "<leader>wR", "<cmd>wincmd R<cr>", { desc = "Rotate up/left" })
vim.keymap.set("n", "<leader>wH", "<cmd>wincmd H<cr>", { desc = "Move left" })
vim.keymap.set("n", "<leader>wJ", "<cmd>wincmd J<cr>", { desc = "Move down" })
vim.keymap.set("n", "<leader>wK", "<cmd>wincmd K<cr>", { desc = "Move up" })
vim.keymap.set("n", "<leader>wL", "<cmd>wincmd L<cr>", { desc = "Move right" })
vim.keymap.set("n", "<leader>w=", "<cmd>wincmd =<cr>", { desc = "Equalize size" })
vim.keymap.set("n", "<leader>wk", "<cmd>resize +5<cr>", { desc = "Resize up" })
vim.keymap.set("n", "<leader>wj", "<cmd>resize -5<cr>", { desc = "Resize down" })
vim.keymap.set("n", "<leader>wh", "<cmd>vertical resize +3<cr>", { desc = "Resize left" })
vim.keymap.set("n", "<leader>wl", "<cmd>vertical resize -3<cr>", { desc = "Resize right" })
vim.keymap.set("n", "<leader>=", "<C-w>=", { desc = "Equalize split window sizes" })
vim.keymap.set("n", "<leader>m", ":MaximizerToggle<cr>", { desc = "Toggle window maximization" })
vim.keymap.set("n", "<leader>rw", ":RotateWindows<cr>", { desc = "Rotate open windows" })

-- ---------------------------------------------------------------------------
-- Files
-- ---------------------------------------------------------------------------
vim.keymap.set("n", "<leader>fn", "<cmd>enew<cr>", { desc = "New file" })
vim.keymap.set("n", "<leader>fs", "<cmd>w<cr>", { desc = "Save file" })
vim.keymap.set("n", "<leader>fo", "gf", { desc = "Open path under cursor" })

-- Format
vim.keymap.set("n", "<leader>f", function()
	require("conform").format({
		async = true,
		timeout_ms = 500,
		lsp_format = "fallback",
	})
end, { desc = "Format the current buffer" })

-- ---------------------------------------------------------------------------
-- Diagnostics
-- ---------------------------------------------------------------------------
vim.keymap.set("n", "]d", function()
	local ok = pcall(vim.diagnostic.jump, { count = 1, float = false })
	if ok then
		vim.api.nvim_feedkeys("zz", "n", false)
	end
end, { desc = "Go to next diagnostic and center" })

vim.keymap.set("n", "[d", function()
	local ok = pcall(vim.diagnostic.jump, { count = -1, float = false })
	if ok then
		vim.api.nvim_feedkeys("zz", "n", false)
	end
end, { desc = "Go to previous diagnostic and center" })

vim.keymap.set("n", "]e", function()
	local ok = pcall(vim.diagnostic.jump, { count = 1, severity = vim.diagnostic.severity.ERROR, float = false })
	if ok then
		vim.api.nvim_feedkeys("zz", "n", false)
	end
end, { desc = "Go to next error diagnostic and center" })

vim.keymap.set("n", "[e", function()
	local ok = pcall(vim.diagnostic.jump, { count = -1, severity = vim.diagnostic.severity.ERROR, float = false })
	if ok then
		vim.api.nvim_feedkeys("zz", "n", false)
	end
end, { desc = "Go to previous error diagnostic and center" })

vim.keymap.set("n", "]w", function()
	local ok = pcall(vim.diagnostic.jump, { count = 1, severity = vim.diagnostic.severity.WARN, float = false })
	if ok then
		vim.api.nvim_feedkeys("zz", "n", false)
	end
end, { desc = "Go to next warning diagnostic and center" })

vim.keymap.set("n", "[w", function()
	local ok = pcall(vim.diagnostic.jump, { count = -1, severity = vim.diagnostic.severity.WARN, float = false })
	if ok then
		vim.api.nvim_feedkeys("zz", "n", false)
	end
end, { desc = "Go to previous warning diagnostic and center" })

vim.keymap.set("n", "<leader>d", function()
	vim.diagnostic.open_float({ border = "rounded" })
end, { desc = "Open diagnostic float" })

vim.keymap.set("n", "<leader>cd", copy_line_diagnostics_to_clipboard, { desc = "Copy line diagnostics" })
vim.keymap.set("n", "<leader>ld", vim.diagnostic.setqflist, { desc = "Populate quickfix with diagnostics" })

-- Quickfix navigation
vim.keymap.set("n", "<leader>cn", ":cnext<cr>zz", { desc = "Next quickfix item" })
vim.keymap.set("n", "<leader>cp", ":cprevious<cr>zz", { desc = "Previous quickfix item" })
vim.keymap.set("n", "<leader>co", ":copen<cr>zz", { desc = "Open quickfix list" })
vim.keymap.set("n", "<leader>cc", ":cclose<cr>zz", { desc = "Close quickfix list" })

-- ---------------------------------------------------------------------------
-- Harpoon
-- ---------------------------------------------------------------------------
vim.keymap.set("n", "<leader>ho", function()
	require("harpoon.ui").toggle_quick_menu()
end, { desc = "Toggle Harpoon quick menu" })

vim.keymap.set("n", "<leader>ha", function()
	require("harpoon.mark").add_file()
end, { desc = "Add current file to Harpoon" })

vim.keymap.set("n", "<leader>hr", function()
	require("harpoon.mark").rm_file()
end, { desc = "Remove current file from Harpoon" })

vim.keymap.set("n", "<leader>hc", function()
	require("harpoon.mark").clear_all()
end, { desc = "Clear all Harpoon marks" })

for i = 1, 5 do
	vim.keymap.set("n", "<leader>" .. i, function()
		require("harpoon.ui").nav_file(i)
	end, { desc = "Navigate to Harpoon file " .. i })
end

-- ---------------------------------------------------------------------------
-- Misc
-- ---------------------------------------------------------------------------
vim.keymap.set("n", "gx", open_link, { silent = true, desc = "Open link under cursor" })
vim.keymap.set("n", "<leader>ut", ":UndotreeToggle<CR>", { desc = "Toggle UndoTree" })
vim.keymap.set("n", "<leader>so", ":Outline<cr>", { desc = "Toggle symbol outline" })
vim.keymap.set("n", "<leader>tc", ":TSC<cr>", { desc = "Run TypeScript compile" })

-- ---------------------------------------------------------------------------
-- LSP keybinds (attached per-buffer)
-- Focus: go to def, go back, open def in splits, open search results in splits
-- ---------------------------------------------------------------------------
M.map_lsp_keybinds = function(buffer_number)
	local opts = { buffer = buffer_number }

	-- Core navigation
	vim.keymap.set("n", "gd", function()
		vim.lsp.buf.definition()
		vim.cmd("normal! zz")
	end, vim.tbl_extend("force", opts, { desc = "LSP: Go to definition" }))

	vim.keymap.set("n", "gD", function()
		vim.lsp.buf.declaration()
		vim.cmd("normal! zz")
	end, vim.tbl_extend("force", opts, { desc = "LSP: Go to declaration" }))

	vim.keymap.set("n", "gr", function()
		require("telescope.builtin").lsp_references()
	end, vim.tbl_extend("force", opts, { desc = "LSP: Go to references" }))

	vim.keymap.set("n", "gi", function()
		require("telescope.builtin").lsp_implementations()
	end, vim.tbl_extend("force", opts, { desc = "LSP: Go to implementations" }))

	vim.keymap.set("n", "td", function()
		vim.lsp.buf.type_definition()
		vim.cmd("normal! zz")
	end, vim.tbl_extend("force", opts, { desc = "LSP: Type definition" }))

	-- Open definition in splits (your navigation workflow)
	vim.keymap.set(
		"n",
		"<leader>gd",
		open_lsp_in_split("vsplit", vim.lsp.buf.definition),
		vim.tbl_extend("force", opts, { desc = "LSP: Definition in vsplit" })
	)
	vim.keymap.set(
		"n",
		"<leader>gD",
		open_lsp_in_split("split", vim.lsp.buf.definition),
		vim.tbl_extend("force", opts, { desc = "LSP: Definition in hsplit" })
	)
	vim.keymap.set(
		"n",
		"<leader>gt",
		open_lsp_in_split("vsplit", vim.lsp.buf.type_definition),
		vim.tbl_extend("force", opts, { desc = "LSP: Type def in vsplit" })
	)

	-- Hover / signature
	vim.keymap.set("n", "K", function()
		vim.lsp.buf.hover({ border = "rounded" })
	end, vim.tbl_extend("force", opts, { desc = "LSP: Hover" }))

	vim.keymap.set("i", "<C-k>", function()
		vim.lsp.buf.signature_help({ border = "rounded" })
	end, vim.tbl_extend("force", opts, { desc = "LSP: Signature help" }))

	-- Actions
	vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "LSP: Rename" }))
	vim.keymap.set(
		{ "n", "v" },
		"<leader>ca",
		vim.lsp.buf.code_action,
		vim.tbl_extend("force", opts, { desc = "LSP: Code action" })
	)

	-- Symbols
	vim.keymap.set("n", "<leader>bs", function()
		require("telescope.builtin").lsp_document_symbols()
	end, vim.tbl_extend("force", opts, { desc = "LSP: Document symbols" }))

	vim.keymap.set("n", "<leader>ps", function()
		require("telescope.builtin").lsp_workspace_symbols()
	end, vim.tbl_extend("force", opts, { desc = "LSP: Workspace symbols" }))

	-- Allaman-style <leader>l* cluster for muscle memory
	vim.keymap.set("n", "<leader>ll", function()
		vim.diagnostic.open_float({ border = "rounded" })
	end, vim.tbl_extend("force", opts, { desc = "Line diagnostics" }))

	vim.keymap.set("n", "<leader>lk", function()
		vim.lsp.buf.hover({ border = "rounded" })
	end, vim.tbl_extend("force", opts, { desc = "Hover" }))

	vim.keymap.set("n", "<leader>la", vim.lsp.buf.code_action, vim.tbl_extend("force", opts, { desc = "Code action" }))
	vim.keymap.set("n", "<leader>lR", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename" }))
	vim.keymap.set("n", "<leader>li", "<cmd>LspInfo<cr>", vim.tbl_extend("force", opts, { desc = "Lsp Info" }))

	vim.keymap.set("n", "<leader>lr", function()
		require("telescope.builtin").lsp_references()
	end, vim.tbl_extend("force", opts, { desc = "References" }))

	vim.keymap.set("n", "<leader>lI", function()
		require("telescope.builtin").lsp_implementations()
	end, vim.tbl_extend("force", opts, { desc = "Implementations" }))

	vim.keymap.set("n", "<leader>lt", function()
		require("telescope.builtin").lsp_type_definitions()
	end, vim.tbl_extend("force", opts, { desc = "Type definitions" }))

	vim.keymap.set("n", "<leader>ls", function()
		require("telescope.builtin").lsp_document_symbols()
	end, vim.tbl_extend("force", opts, { desc = "Document symbols" }))

	vim.keymap.set("n", "<leader>lws", function()
		require("telescope.builtin").lsp_dynamic_workspace_symbols()
	end, vim.tbl_extend("force", opts, { desc = "Workspace symbols" }))

	vim.keymap.set("n", "<leader>ln", function()
		vim.diagnostic.jump({ count = 1 })
	end, vim.tbl_extend("force", opts, { desc = "Next diagnostic" }))

	vim.keymap.set("n", "<leader>lp", function()
		vim.diagnostic.jump({ count = -1 })
	end, vim.tbl_extend("force", opts, { desc = "Prev diagnostic" }))
end

-- ---------------------------------------------------------------------------
-- Telescope: open search results in splits (C-v / C-x already default in
-- telescope; reinforce + add which-key friendly aliases in telescope.lua)
-- ---------------------------------------------------------------------------

-- Treesitter selection + textobjects
local treesitter_select = function()
	if not vim.treesitter.get_parser(0, nil, { error = false }) then
		return nil
	end
	local ok, select = pcall(require, "vim.treesitter._select")
	if ok then
		return select
	end
	return nil
end

local treesitter_select_parent = function()
	local select = treesitter_select()
	if select then
		select.select_parent(vim.v.count1)
	else
		vim.lsp.buf.selection_range(vim.v.count1)
	end
end

local treesitter_select_child = function()
	local select = treesitter_select()
	if select then
		select.select_child(vim.v.count1)
	else
		vim.lsp.buf.selection_range(-vim.v.count1)
	end
end

local treesitter_select_scope = function()
	local ok = pcall(require("nvim-treesitter-textobjects.select").select_textobject, "@local.scope", "locals")
	if not ok then
		treesitter_select_parent()
	end
end

local treesitter_textobject = function(query, query_group)
	return function()
		require("nvim-treesitter-textobjects.select").select_textobject(query, query_group or "textobjects")
	end
end

local treesitter_move = function(method, query, query_group)
	return function()
		require("nvim-treesitter-textobjects.move")[method](query, query_group or "textobjects")
	end
end

vim.keymap.set("n", "<C-Space>", function()
	if treesitter_select() then
		vim.cmd.normal({ "van", bang = true })
	else
		vim.lsp.buf.selection_range(1)
	end
end, { desc = "Treesitter: Start incremental selection" })

vim.keymap.set("x", "<C-Space>", treesitter_select_parent, { desc = "Treesitter: Expand selection" })
vim.keymap.set("x", "<C-s>", treesitter_select_scope, { desc = "Treesitter: Expand to scope" })
vim.keymap.set("x", "<C-BS>", treesitter_select_child, { desc = "Treesitter: Shrink selection" })

vim.keymap.set({ "x", "o" }, "aa", treesitter_textobject("@parameter.outer"), { desc = "Select outer parameter" })
vim.keymap.set({ "x", "o" }, "ia", treesitter_textobject("@parameter.inner"), { desc = "Select inner parameter" })
vim.keymap.set({ "x", "o" }, "af", treesitter_textobject("@function.outer"), { desc = "Select outer function" })
vim.keymap.set({ "x", "o" }, "if", treesitter_textobject("@function.inner"), { desc = "Select inner function" })
vim.keymap.set({ "x", "o" }, "ac", treesitter_textobject("@class.outer"), { desc = "Select outer class" })
vim.keymap.set({ "x", "o" }, "ic", treesitter_textobject("@class.inner"), { desc = "Select inner class" })

vim.keymap.set(
	{ "n", "x", "o" },
	"]m",
	treesitter_move("goto_next_start", "@function.outer"),
	{ desc = "Next function start" }
)
vim.keymap.set(
	{ "n", "x", "o" },
	"]]",
	treesitter_move("goto_next_start", "@class.outer"),
	{ desc = "Next class start" }
)
vim.keymap.set(
	{ "n", "x", "o" },
	"]M",
	treesitter_move("goto_next_end", "@function.outer"),
	{ desc = "Next function end" }
)
vim.keymap.set({ "n", "x", "o" }, "][", treesitter_move("goto_next_end", "@class.outer"), { desc = "Next class end" })
vim.keymap.set(
	{ "n", "x", "o" },
	"[m",
	treesitter_move("goto_previous_start", "@function.outer"),
	{ desc = "Previous function start" }
)
vim.keymap.set(
	{ "n", "x", "o" },
	"[[",
	treesitter_move("goto_previous_start", "@class.outer"),
	{ desc = "Previous class start" }
)
vim.keymap.set(
	{ "n", "x", "o" },
	"[M",
	treesitter_move("goto_previous_end", "@function.outer"),
	{ desc = "Previous function end" }
)
vim.keymap.set(
	{ "n", "x", "o" },
	"[]",
	treesitter_move("goto_previous_end", "@class.outer"),
	{ desc = "Previous class end" }
)

return M
