vim.o.completeopt = "menuone,noselect,noinsert"
vim.o.showmode = false

vim.g.coq_settings = {
  keymap = {
    recommended = false,
    jump_to_mark = "<m-,>",
  },
  clients = {
    snippets = {
      warn = {},
    },
    paths = {
      path_seps = {
        "/",
      },
    },
    buffers = {
      match_syms = false,
    },
    third_party = {
      enabled = true,
    },
    lsp = {
      weight_adjust = 1,
    },
  },
  display = {
    ghost_text = {
      enabled = true,
    },
    -- preview = {
    --   border = vim.g.lsp_borders,
    -- },
    pum = {
      fast_close = false,
    },
  },
  match = {
    unifying_chars = {
      "-",
      "_",
    },
  },
  limits = {
    completion_auto_timeout = 1.0,
    completion_manual_timeout = 1.0,
  },
}

vim.schedule(function()
  vim.cmd.COQnow "--shut-up"
end)

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
