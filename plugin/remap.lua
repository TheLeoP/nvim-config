-- :fennel:1692395619
local function _1_()
  local _2_ = vim.bo.filetype
  if (_2_ == "lua") then
    vim.cmd("silent! write")
    vim.cmd("source %")
    return nil
  elseif (_2_ == "vim") then
    vim.cmd("silent! write")
    vim.cmd("source %")
    return nil
  elseif (_2_ == "fennel") then
    vim.cmd.FnlBuffer()
    return nil
  else
    return nil
  end
end
vim.keymap.set({"n"}, "<leader>x", _1_, {desc = "Execute current buffer (vim, lua or fennel)", silent = true})
return vim.keymap.set({"n"}, "<leader><leader>t", "<cmd>tab split<cr>", {silent = true})
