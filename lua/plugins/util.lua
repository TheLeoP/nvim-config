return {
  "tpope/vim-repeat",
  {
    "nvim-lua/plenary.nvim",
    config = function()
      vim.api.nvim_create_autocmd("BufRead", {
        group = vim.api.nvim_create_augroup("Plenary test", { clear = true }),
        pattern = "*_spec.lua",
        callback = function(opts)
          ---@type integer
          local bufnr = opts.buf
          vim.keymap.set("n", "t", "<Plug>PlenaryTestFile", { buffer = bufnr })
        end,
      })
    end,
  },
  {
    "lambdalisue/suda.vim",
    init = function()
      vim.g["suda#prompt"] = "Contraseña: "

      if vim.fn.has "win32" ~= 1 then
        vim.g.suda_smart_edit = 0
      end
    end,
  },
}
