-- Run from the repo root: lua tests/rex-close-pane.lua
local view, run, queued
rex = {
	action = function(action) run = action.run end,
	session = { view = function() return view end },
	client = { queue = function(action) queued = action end },
}
dofile("home/.config/rex/v36372/close_pane_or_tab.lua")

local function window(id, ...)
	local layers = {}
	for _, block_id in ipairs({...}) do
		layers[#layers + 1] = { blocks = {{ block_id = block_id }} }
	end
	return { window_id = id, layers = layers }
end

local function check(block_id, expected)
	queued = nil
	run({ block_id = block_id })
	assert(queued == expected, tostring(block_id) .. ": expected " .. expected .. ", got " .. tostring(queued))
end

view = { active_window_id = "one", windows = { window("one", "a"), window("two", "b", "floating") } }
check("a", "client.tab.close")
check("b", "pane.close") -- Use the targeted pane's tab; count floating panes too.
check(nil, "client.tab.close")
check("missing", "pane.close")
view = nil
check("a", "pane.close")
print("Rex close-pane checks passed")
