local api = vim.api

return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdateSync",
  opts = {
    ensure_installed = {
      "c",
      "doxygen",
      "re2c",
      "lua",
      "luap",
      "printf",
      "luadoc",
      "vim",
      "vimdoc",
      "query",
      "xml",
      "http",
      "json",
      "graphql",
      "jsdoc",
      "regex",

      "angular",
      "scss",
    },
    sync_install = true,
    auto_install = true,
    ignore_install = {
      "thrift",
      "comment",
    },
    highlight = {
      enable = true,
    },
  },
  config = function(_, opts)
    if vim.fn.has "win32" == 1 then require("nvim-treesitter.install").compilers = { "clang" } end
    require("nvim-treesitter.configs").setup(opts)

    api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
      pattern = { "*.component.html", "*.container.html" },
      callback = function() vim.treesitter.start(nil, "angular") end,
    })
  end,
}
