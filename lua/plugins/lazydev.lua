return {
  "folke/lazydev.nvim",
  ---@module "lazydev"
  ---@type lazydev.Config
  opts = {
    cmp = false,
    library = {
      { path = "${3rd}/luv/library", words = { "vim%.uv", 'require "luv"' } },
      { path = "${3rd}/love2d/library", words = { "love%." } },
      { path = "busted/library", words = { "it%(", "describe%(" } },
      { path = "luassert/library", words = { "it%(", "describe%(" } },
      { path = "lpeg/library", words = { 'require "lpeg"' } },
      { path = "wezterm-types", mods = { "wezterm" } },
    },
    integrations = {
      lspconfig = false,
      cmp = false,
    },
    enabled = function(root_dir)
      return not vim.uv.fs_stat(root_dir .. "/.luarc.json") and not vim.uv.fs_stat(root_dir .. "/.luarc.jsonc")
    end,
  },
  dependencies = {
    "justinsgithub/wezterm-types",
    "LuaCATS/busted",
    "LuaCATS/lpeg",
    "LuaCATS/luassert",
  },
}
