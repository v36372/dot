-- Run from the repo root: lua tests/rex-pane-navigation.lua
local bindings, before, after, request = {}, { revision = 1 }, { revision = 2 }, nil
rex = {
	bind = function(key, action) bindings[key] = action end,
	session = {
		view = function() return before end,
		focus_direction = function(args)
			request = args
			return after
		end,
	},
}
dofile("home/.config/rex/v36372/keymaps.lua")

for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
	assert(bindings["ctrl+" .. key]() == true)
	assert(request.direction == direction and request.wrap == false)
end

local right = bindings["ctrl+l"]
after = before
assert(right() == false, "no neighbor: pass Ctrl+L through")
after = nil
assert(right() == false, "focus call failed: pass Ctrl+L through")
before, request = nil, nil
assert(right() == false and request == nil, "no view: pass through without moving focus")
print("Rex pane navigation checks passed")
