-- impatient.nvim
local succes, _ = pcall(require, "impatient")
if not succes then
	require("personal.install")
end

-- funciones y variable globales peronales
require("personal.globals")

-- vim polyglot
require("personal.polyglot")

-- plugin
require("personal.packer")

-- lua/colorscheme
require("personal.colorscheme")

-- neovide config
require("personal.neovide")
