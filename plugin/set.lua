-- Folding.
vim.o.foldcolumn = "1"
vim.o.foldlevelstart = 99
vim.o.foldmethod = "expr"
vim.wo.foldtext = "v:lua.vim.treesitter.foldtext()"
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
