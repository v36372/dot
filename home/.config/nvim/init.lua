if vim.loader then
	vim.loader.enable()
end

-- _G.dd = function(...)
--     require("util.debug").dump(...)
-- end
-- vim.print = _G.dd

_G.V36372 = require("v36372.utils")
require("v36372.config.options")
require("v36372.config.keymaps")
require("v36372.config.autocmds")
require("v36372.config.commands")
require("v36372.config.workarounds")
require("v36372.plugins")
