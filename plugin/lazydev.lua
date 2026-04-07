vim.pack.add {
  "https://github.com/LuaCATS/luassert",
  "https://github.com/LuaCATS/lpeg",
  "https://github.com/LuaCATS/busted",
  "https://github.com/justinsgithub/wezterm-types",
  "https://github.com/folke/lazydev.nvim",
}

require("lazydev").setup {
  cmp = false,
  library = {
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
}
