return {
	{
		"mbbill/undotree",
		event = { "BufReadPost" },
		lazy = true,
		config = function()
			if vim.fn.has("persistent_undo") == 1 then
				local target_path = vim.fn.stdpath("state") .. "/undo//"
				vim.fn.mkdir(target_path, "p")
				vim.opt.undodir = target_path
				vim.opt.undofile = true
			end
		end,
	},
}
