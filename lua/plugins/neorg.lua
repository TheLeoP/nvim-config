return {
  "nvim-neorg/neorg",
  opts = {
    load = {
      ["core.defaults"] = {}, -- Loads default behaviour
      ["core.concealer"] = {}, -- Adds pretty icons to your documents
      ["core.dirman"] = { -- Manages Neorg workspaces
        config = {
          workspaces = {
            notes = "~/notes",
            work = "~/work",
          },
          default_workspace = "notes",
        },
      },
      ["core.presenter"] = {
        config = {
          zen_mode = "zen-mode",
        },
      },
    },
  },
  dependencies = {
    "folke/zen-mode.nvim",
    "luarocks.nvim",
  },
}
