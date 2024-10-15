return {
  "RRethy/vim-illuminate",
  config = function()
    require("illuminate").configure {
      filetype_overrides = {
        cs = { providers = { "treesitter", "regex" } },
      },
      filetypes_denylist = {
        "",
      },
    }
  end,
}
