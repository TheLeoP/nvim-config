return {
  {
    "nvim-neorg/neorg",
    enabled = true,
    build = ":Neorg sync-parsers",
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
      },
    },
  },
}
