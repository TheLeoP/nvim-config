---@module "mini.ai"

vim.b.minisurround_config = {
  custom_surroundings = {
    s = {
      input = { "%[%[().-()%]%]" },
      output = { left = "[[", right = "]]" },
    },
  },
}

vim.b.miniai_config = {
  custom_textobjects = {
    s = MiniAi.gen_spec.pair("[[", "]]"),
  },
}
