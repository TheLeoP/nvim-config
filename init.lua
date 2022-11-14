-- impatient.nvim
local succes, _ = pcall(require, "impatient")
if not succes then
  require "personal.config.install"
end

-- funciones y variable globales personales
require "personal.config.globals"

-- vim polyglot
require "personal.config.polyglot"

-- plugin
require "personal.config.packer"

-- lua/colorscheme
require "personal.config.colorscheme"

-- neovide config
require "personal.config.neovide"
