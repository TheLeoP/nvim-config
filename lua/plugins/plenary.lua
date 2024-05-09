return {
  "nvim-lua/plenary.nvim",
  config = function()
    vim.api.nvim_create_autocmd("BufRead", {
      group = vim.api.nvim_create_augroup("Plenary test", { clear = true }),
      pattern = "*_spec.lua",
      callback = function(opts)
        local bufnr = opts.buf ---@type integer
        vim.keymap.set("n", "t", "<Plug>PlenaryTestFile", { buffer = bufnr })
      end,
    })
  end,
}
