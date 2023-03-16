vim.keymap.set("i", "<BS>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-e><BS>"
  else
    return "<BS>"
  end
end, { expr = true, silent = true })

vim.keymap.set("i", "<CR>", function()
  if vim.fn.pumvisible() == 1 then
    if vim.fn.complete_info().selected == -1 then
      return "<C-e><CR>"
    else
      return "<C-y>"
    end
  else
    return "<CR>"
  end
end, { expr = true, silent = true })

vim.keymap.set("i", "<Tab>", function()
  if vim.fn.pumvisible() == 1 then
    return "<down>"
  else
    return "<Tab>"
  end
end, { expr = true, silent = true })

vim.keymap.set("i", "<s-tab>", function()
  if vim.fn.pumvisible() == 1 then
    return "<up>"
  else
    return "<BS>"
  end
end, { expr = true, silent = true })
