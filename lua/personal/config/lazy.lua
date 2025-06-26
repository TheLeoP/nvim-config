vim.g.mapleader = " "
vim.g.maplocalleader = "'"

---@type string
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
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

local documents = vim.env.HOME .. "/Documentos" ---@type string
local personal = documents .. "/Personal"
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
    path = personal,
  },
  install = {
    colorscheme = { "gruvbox" },
  },
  readme = {
    enabled = false,
  },
  rocks = {
    hererocks = true,
  },
})
