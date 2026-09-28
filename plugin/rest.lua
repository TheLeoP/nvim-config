vim.pack.add { "https://github.com/TheLeoP/rest.nvim" }

local group = vim.api.nvim_create_augroup("personal.rest", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  group = group,
  callback = function(args)
    local buf = args.buf

    vim.keymap.set("n", "<localleader>r", "<cmd>Rest run<cr>", { buf = buf })
    vim.keymap.set("n", "<localleader>v", "<cmd>vertical Rest open<cr>", { buf = buf })
    vim.keymap.set("n", "<localleader><", "<cmd>Rest last<cr>", { buf = buf })
  end,
})
