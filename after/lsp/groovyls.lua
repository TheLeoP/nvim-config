---@type vim.lsp.Config
return {
  cmd = { "groovy-language-server" },
  settings = {
    groovy = {
      classpath = vim.list_extend(
        vim.split(vim.fn.glob(vim.env.HOME .. "/.gradle/caches/modules-2/files-2.1/**/*.jar"), "\n"),
        vim.split(vim.fn.glob(vim.env.HOME .. "/.jenkins/**/*.jar"), "\n")
      ),
    },
  },
}
