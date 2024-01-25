-- :fennel:1705369409
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
vim.keymap.set({"n"}, "<leader><leader>x", _1_, {desc = "Execute current buffer (vim, lua or fennel)"})
return vim.keymap.set({"n"}, "<leader><leader>t", "<cmd>tab split<cr>")