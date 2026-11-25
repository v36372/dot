-- Based on https://github.com/dmmulroy/.dotfiles/tree/main/home/.config/rex
local prefix_key = "ctrl+s"
local prefix = prefix_key .. ">"

-- Press the prefix twice to send it to the terminal.
rex.bind(prefix .. prefix_key, "pane.send_key", { key = prefix_key })

-- App and sessions
rex.bind("cmd+n", "session.new")
rex.bind("cmd+shift+n", "client.window.new")

rex.bind(prefix .. "shift+/", "client.palette.toggle")
rex.bind(prefix .. "shift+s", "client.settings")
rex.bind(prefix .. "r", "client.config.reload")
rex.bind(prefix .. "b", "client.sidebar.toggle")

rex.bind(prefix .. "shift+n", "session.new")
rex.bind(prefix .. "shift+w", "session.rename")
rex.bind(prefix .. "shift+d", "session.close")
rex.bind(prefix .. "s", "session.switch")
rex.bind(prefix .. "w", "session.switch")
rex.bind(prefix .. "g", "session.switch")
rex.bind(prefix .. "shift+9", "session.previous")
rex.bind(prefix .. "shift+0", "session.next")

-- Tabs
rex.bind(prefix .. "c", "client.tab.new")
rex.bind(prefix .. ",", "client.tab.rename")
rex.bind(prefix .. "p", "client.tab.previous")
rex.bind(prefix .. "n", "client.tab.next")
rex.bind(prefix .. "shift+x", "client.tab.close")

for i = 1, 9 do
	rex.bind(prefix .. i, "client.tab.goto", { index = i })
end

-- Panes
rex.bind(prefix .. "/", "pane.split", { direction = "right" })
rex.bind(prefix .. "enter", "pane.split", { direction = "down" })
rex.bind(prefix .. "x", "close_pane_or_tab")
rex.bind(prefix .. "m", "pane.zoom")
rex.bind(prefix .. "tab", "pane.focus_next")
rex.bind(prefix .. "shift+tab", "pane.focus_previous")
rex.bind(prefix .. "v", "client.find.open")
rex.bind(prefix .. "shift+r", "client.mode.enter", { name = "resize" })

for key, direction in pairs({ h = "left", j = "down", k = "up", l = "right" }) do
	rex.bind(prefix .. key, "pane.focus", { direction = direction })
	rex.bind("ctrl+" .. key, function()
		-- Leave shell/editor shortcuts alone when there is no pane that way.
		local before = rex.session.view({})
		if not before then return false end
		local after = rex.session.focus_direction({ direction = direction, wrap = false })
		return after ~= nil and after.revision ~= before.revision
	end)
	rex.bind(prefix .. "shift+" .. key, "pane.move", { direction = direction })
end
