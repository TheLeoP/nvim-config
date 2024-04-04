vim.opt.number = true
vim.opt.relativenumber = true

vim.opt.wrap = false

vim.opt.spelllang = { "es", "en", "de" }

vim.opt.swapfile = false
vim.opt.undofile = true

vim.opt.clipboard = "unnamedplus"

vim.opt.hlsearch = true

vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.expandtab = true
vim.opt.shiftwidth = 4

vim.opt.scrolloff = 8

vim.opt.cmdheight = 2

vim.opt.showmode = false

vim.opt.signcolumn = "yes"

vim.opt.updatetime = 300
vim.opt.timeoutlen = 500

vim.opt.guifont = "CaskaydiaCove Nerd Font Mono:h12"

if vim.fn.executable "rg" == 1 then
  vim.opt.grepprg = "rg --vimgrep --hidden"
  vim.opt.grepformat = "%f:%l:%c:%m"
end

vim.opt.mouse = "a"

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.laststatus = 3

vim.opt.cursorline = true

vim.opt.diffopt:append { "vertical", "context:99" }

vim.opt.shortmess:append "w"
vim.opt.shortmess:append "s"

vim.opt.breakindent = true

-- Disable health checks for these providers.
vim.g.loaded_python3_provider = 0
vim.g.loaded_ruby_provider = 0
vim.g.loaded_perl_provider = 0
vim.g.loaded_node_provider = 0

-- Folding.
vim.o.foldcolumn = "1"
vim.o.foldlevelstart = 99
vim.o.foldmethod = "expr"
vim.wo.foldtext = ""
vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"

local arrows = {
  right = "",
  left = "",
  up = "",
  down = "",
}

vim.opt.fillchars = {
  eob = " ",
  fold = " ",
  foldclose = arrows.right,
  foldopen = arrows.down,
  foldsep = " ",
  msgsep = "─",
}

vim.o.exrc = true
