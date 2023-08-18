vim.g.mapleader = " "
vim.g.maplocalleader = ","

---@type string
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "--single-branch",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  }
end
vim.opt.runtimepath:prepend(lazypath)

require("lazy").setup("plugins", {
  performance = {
    cache = {
      enabled = false,
    },
    reset_packpath = false,
    rtp = {
      reset = false,
    },
  },
  dev = {
    path = vim.g.documentos .. "/Personal",
  },
  install = {
    colorscheme = { "gruvbox" },
  },
})
