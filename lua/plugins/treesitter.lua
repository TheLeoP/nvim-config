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
    },
    sync_install = true,
    auto_install = true,
    ignore_install = {
      "thrift",
      "comment",
    },
    highlight = {
      enable = true, -- false will disable the whole extension
      disable = {
        "dashboard",
      },
    },
  },
  config = function(_, opts)
    if vim.fn.has "win32" == 1 then require("nvim-treesitter.install").compilers = { "clang" } end
    require("nvim-treesitter.configs").setup(opts)
  end,
}
