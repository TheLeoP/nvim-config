local o = vim.o
local opt = vim.opt
local wo = vim.wo

opt.number = true
opt.relativenumber = true

opt.wrap = false

opt.spelllang = { "es", "en", "de" }

opt.swapfile = false
opt.undofile = true

opt.clipboard = "unnamedplus"

opt.hlsearch = true

opt.ignorecase = true
opt.smartcase = true

opt.expandtab = true
opt.shiftwidth = 4

opt.scrolloff = 8

opt.cmdheight = 2

opt.showmode = false

opt.signcolumn = "yes"

opt.updatetime = 300
opt.timeoutlen = 500

opt.guifont = "CaskaydiaCove Nerd Font Mono:h12"

if vim.fn.executable "rg" == 1 then
  opt.grepprg = "rg --vimgrep --hidden"
  opt.grepformat = "%f:%l:%c:%m"
end

opt.mouse = "a"

opt.splitbelow = true
opt.splitright = true

opt.laststatus = 3

opt.cursorline = true

opt.diffopt:append { "vertical", "context:99" }

opt.shortmess:append "sWcC"

opt.breakindent = true

-- Disable health checks for these providers.
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

-- Folding.
o.foldcolumn = "1"
o.foldlevelstart = 99
o.foldmethod = "expr"
wo.foldtext = ""
wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

local arrows = require("personal.icons").arrows

opt.fillchars = {
  eob = " ",
  fold = " ",
  foldclose = arrows.right,
  foldopen = arrows.down,
  foldsep = " ",
  msgsep = "─",
}

o.exrc = true

o.listchars = "tab:> ,extends:…,precedes:…,nbsp:␣"
o.list = true

o.pumblend = 10
o.winblend = 10

o.sessionoptions = "help,winsize,winpos"
