return {
  {
    "udayvir-singh/tangerine.nvim",
    opts = {
      ---@type string
      target = vim.fn.stdpath [[data]] .. "/tangerine",
      rtpdirs = {
        "plugin",
      },
      compiler = {
        verbose = false,
        hooks = { "onsave", "oninit" },
      },
    },
  },
  {
    "udayvir-singh/hibiscus.nvim",
  },
}
