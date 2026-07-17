local M = {}

--- Returns the current cursor position.
--- @param opts? { zero_indexed?: boolean }
--- @return { row: integer, col: integer }
local function get_cursor_position(opts)
	opts = opts or {}
	local zero_indexed = opts.zero_indexed or false
	local pos = vim.api.nvim_win_get_cursor(0)

	if zero_indexed then
		return { row = pos[1] - 1, col = pos[2] }
	end
	return { row = pos[1], col = pos[2] }
end

M.get_cursor_position = get_cursor_position

local function copy_line_diagnostics_to_clipboard()
	local ok, diag = pcall(require, "tiny-inline-diagnostic")
	local diagnostics

	if ok and diag.get_diagnostic_under_cursor then
		diagnostics = diag.get_diagnostic_under_cursor()
	else
		local lnum = vim.api.nvim_win_get_cursor(0)[1] - 1
		diagnostics = vim.diagnostic.get(0, { lnum = lnum })
	end

	if not diagnostics or #diagnostics == 0 then
		Snacks.notify.info("No diagnostics on the current line.")
		return
	end

	local diagnostic_messages = {}
	for _, diagnostic in ipairs(diagnostics) do
		table.insert(diagnostic_messages, diagnostic.message)
	end
	local result = table.concat(diagnostic_messages, "\n")

	vim.fn.setreg("+", result)
	Snacks.notify.info("Diagnostics copied to clipboard.")
end

M.copy_line_diagnostics_to_clipboard = copy_line_diagnostics_to_clipboard

local function open_link()
	local line = vim.fn.getline(".")
	local col = vim.fn.col(".")

	local md_link_pattern = "%[.-%]%((.-)%)"
	local url_pattern = "https?://[%w-_%.%?%.:/%+=&]+"
	local opener = vim.fn.executable("xdg-open") == 1 and "xdg-open" or "open"

	local start_pos = 1
	while true do
		local md_start, md_end, url = line:find(md_link_pattern, start_pos)
		if not md_start then
			break
		end

		if col >= md_start and col <= md_end then
			vim.fn.system({ opener, url })
			return
		end
		start_pos = md_end + 1
	end

	start_pos = 1
	while true do
		local url_start, url_end = line:find(url_pattern, start_pos)
		if not url_start then
			break
		end

		if col >= url_start and col <= url_end then
			local url = line:sub(url_start, url_end)
			vim.fn.system({ opener, url })
			return
		end
		start_pos = url_end + 1
	end

	vim.cmd("sil !" .. opener .. " <cWORD>")
end

M.open_link = open_link

--- Open LSP location in a split, then jump.
--- @param split_cmd "vsplit"|"split"
--- @param lsp_method fun()
local function open_lsp_in_split(split_cmd, lsp_method)
	return function()
		vim.cmd(split_cmd)
		lsp_method()
		vim.cmd("normal! zz")
	end
end

M.open_lsp_in_split = open_lsp_in_split

return M
