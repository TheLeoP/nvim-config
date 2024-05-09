return {
  "nvim-treesitter/nvim-treesitter",
  opts = {
    ensure_installed = {
      "c",
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
