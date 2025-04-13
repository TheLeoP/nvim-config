return {
  "luckasRanarison/tailwind-tools.nvim",
  name = "tailwind-tools",
  build = ":UpdateRemotePlugins",
  dependencies = {
    "nvim-treesitter",
    "nvim-lspconfig",
  },
  ---@module 'tailwind-tools'
  ---@type TailwindTools.Option
  opts = {
    server = {
      override = false,
    },
    document_color = {
      kind = "background",
    },
  },
}
