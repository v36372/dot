-- Close the tab when its last pane is closed.
rex.action({
	name = "close_pane_or_tab",
	title = "Close Pane (or Tab if Last Pane)",
	category = "Panes",
	run = function(ctx)
		local view = rex.session.view({})
		for _, window in ipairs(view and view.windows or {}) do
			local matches = not ctx.block_id and window.window_id == view.active_window_id
			local count = 0
			for _, layer in ipairs(window.layers) do
				for _, block in ipairs(layer.blocks) do
					count = count + 1
					matches = matches or block.block_id == ctx.block_id
				end
			end
			if matches then
				rex.client.queue(count <= 1 and "client.tab.close" or "pane.close", {})
				return
			end
		end
		rex.client.queue("pane.close", {})
	end,
})
