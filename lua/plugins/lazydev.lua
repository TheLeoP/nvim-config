return {
  "folke/lazydev.nvim",
  opts = {
    cmp = false,
    library = {
      { path = "luvit-meta/library", words = { "vim%.uv" } },
    },
    enabled = function(root_dir)
      return not vim.uv.fs_stat(root_dir .. "/.luarc.json") and not vim.uv.fs_stat(root_dir .. "/.luarc.jsonc")
    end,
  },
  dependencies = { "Bilal2453/luvit-meta" },
}
