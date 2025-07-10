local o = vim.o
local opt = vim.opt
local wo = vim.wo

o.number = true
o.relativenumber = true

o.wrap = false

o.spelllang = "es,en,de"

o.swapfile = false
o.undofile = true

o.clipboard = "unnamedplus"

o.hlsearch = true

o.ignorecase = true
o.smartcase = true

o.expandtab = true
o.shiftwidth = 4

o.scrolloff = 8

o.cmdheight = 2

o.showmode = false

o.signcolumn = "yes"

o.updatetime = 300
o.timeoutlen = 500

o.guifont = "CaskaydiaCove Nerd Font Mono:h12"

if vim.fn.executable "rg" == 1 then
  o.grepprg = "rg --vimgrep --hidden"
  o.grepformat = "%f:%l:%c:%m"
end

o.mouse = "a"

o.splitbelow = true
o.splitright = true

o.laststatus = 3
o.ruler = false -- laststatus overrides ruler, but it's still on by default, which stops <c-g> from showing the cursor location

o.cursorline = true

opt.diffopt:append { "vertical", "context:99" }

opt.shortmess:append "sWcC"

o.breakindent = true

-- Disable health checks for these providers.
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

-- Folding.
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

o.sessionoptions = "curdir,tabpages,help,globals,winsize,winpos"

o.linebreak = true

o.nrformats = o.nrformats .. ",blank"
