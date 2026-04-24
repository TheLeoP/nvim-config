local api = vim.api

pcall(vim.cmd.language, "en_US.utf8")

vim.g.mapleader = " "
vim.g.maplocalleader = "'"

local group = api.nvim_create_augroup("personal-vim.pack", { clear = true })
api.nvim_create_autocmd("PackChanged", {
  group = group,
  callback = function(opts)
    ---@type string, 'install'|'update'|'delete', boolean
    local name, kind, active = opts.data.spec.name, opts.data.kind, opts.data.active
    if name == "fzf" and (kind == "install" or kind == "update") then
      if not active then vim.cmd.packadd "fzf" end
      vim.fn["fzf#install"]()
    end
    if name == "nvim-treesitter" and (kind == "install" or kind == "update") then
      if not active then vim.cmd.packadd "nvim-treesitter" end
      vim.cmd.TSUpdate()
    end
    if name == "mason.nvim" and (kind == "install" or kind == "update") then
      if not active then vim.cmd.packadd "mason.nvim" end
      vim.cmd.MasonUpdate()
    end
  end,
})

require "personal.set"
require "personal.config.lsp"
require "personal.config.neovide"
