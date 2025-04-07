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
    document_color = {
      kind = "background",
    },
  },
}
