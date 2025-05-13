return {
  settings = {
    Lua = {
      hint = {
        enable = true,
        arrayIndex = "Disable",
      },
      codelens = {
        enable = true,
      },
      completion = {
        showWord = "Disable",
        keywordSnippet = "Disable",
      },
      diagnostics = {
        groupFileStatus = {
          strict = "Opened",
          strong = "Opened",
        },
        groupSeverity = {
          strict = "Warning",
          strong = "Warning",
        },
        unusedLocalExclude = { "_*" },
        librayFiles = "Disabled",
      },
      workspace = {
        checkThirdParty = "Disable",
      },
    },
  },
}
