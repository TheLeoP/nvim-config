vim.filetype.add {
  extension = {
    props = "xml",
  },
  filename = {
    ["qwerty.txt"] = "kinesis",
    ["dvorak.txt"] = "kinesis",
    [".envrc"] = "sh",
  },
}

vim.filetype.add {
  extension = {
    gotmpl = "gotmpl",
  },
  pattern = {
    [".*/templates/.*%.tpl"] = "helm",
    [".*/templates/.*%.ya?ml"] = "helm",
    ["helmfile.*%.ya?ml"] = "helm",
  },
}
