return {
  "tpope/vim-repeat",
  "nvim-lua/plenary.nvim",
  {
    "lambdalisue/suda.vim",
    init = function()
      vim.g["suda#prompt"] = "Contraseña: "

      if vim.fn.has "win32" ~= 1 then
        vim.g.suda_smart_edit = 1
      end
    end,
  },
}
