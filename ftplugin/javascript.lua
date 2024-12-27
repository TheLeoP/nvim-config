vim.b.minisurround_config = {
  custom_surroundings = {
    ["$"] = {
      input = { "${().-()}" },
      output = { left = "${", right = "}" },
    },
  },
}

vim.b.miniai_config = {
  custom_textobjects = {
    ["$"] = MiniAi.gen_spec.pair("${", "}"),
  },
}
