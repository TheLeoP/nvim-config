local group = vim.api.nvim_create_augroup("firenvim", { clear = true })
vim.api.nvim_create_autocmd("UIEnter", {
  group = group,
  pattern = "*",
  callback = function()
    local event = vim.api.nvim_get_chan_info(vim.v.event.chan)
    if event == nil or event.client == nil then
      return
    end
    local name = event.client.name
    if name == "Firenvim" then
      vim.o.laststatus = 0
      vim.o.winbar = nil
    end
  end,
})
