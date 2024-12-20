return {
  "folke/lazydev.nvim",
  opts = {
    cmp = false,
    library = {
      { path = "${3rd}/luv/library", words = { "vim%.uv" } },
      { path = "busted/library", words = { "it%(", "describe%(" } },
      { path = "wezterm-types", mods = { "wezterm" } },
    },
    integrations = {
      lspconfig = true,
      cmp = false,
      coq = true,
    },
    enabled = function(root_dir)
      return not vim.uv.fs_stat(root_dir .. "/.luarc.json") and not vim.uv.fs_stat(root_dir .. "/.luarc.jsonc")
    end,
  },
  dependencies = {
    "justinsgithub/wezterm-types",
    "LuaCATS/busted",
  },
}
