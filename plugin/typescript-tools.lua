vim.pack.add {
  -- NOTE: check if no other plugin depends on plenary.nvim when removing
  -- plugin
  "https://github.com/pmizio/typescript-tools.nvim",
}

require("typescript-tools").setup {
  root_dir = function(buf, cb)
    local root = vim.fs.root(buf, { ".git" })
    if root then return cb(root) end
    root = vim.fs.root(buf, { "package.json" })
    if root then return cb(root) end
  end,
  settings = {
    tsserver_max_memory = "10240",
    tsserver_file_preferences = {
      includeInlayParameterNameHints = "all",
      includeInlayParameterNameHintsWhenArgumentMatchesName = true,
      includeInlayEnumMemberValueHints = true,
    },
    expose_as_code_action = {
      "add_missing_imports",
      "remove_unused_imports",
      "organize_imports",
    },
  },
}
