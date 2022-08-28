local actions = require "telescope.actions"
local personal_actions = require "personal.fn_telescope"

require("telescope").setup {
  defaults = {
    color_devicons = true,
    path_display = {
      shorten = {
        len = 1,
        exclude = { 1, -1 },
      },
    },
    borderchars = { "━", "┃", "━", "┃", "┏", "┓", "┛", "┗" },
    file_ignore_patterns = {
      "^tags$",
      "%.class$",
      "%.jar$",
      "miniconda3/",
    },

    mappings = {
      i = {
        ["<C-f>"] = actions.send_to_qflist,
        ["<C-u>"] = false,
        ["<C-d>"] = false,
      },
      n = {
        ["q"] = actions.send_to_qflist,
        ["<c-{>"] = actions.close,
      },
    },
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = true,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
    file_browser = {
      mappings = {
        i = {},
        n = {},
      },
    },
  },
}

require("telescope").load_extension "fzf"
require("telescope").load_extension "projects"
require("telescope").load_extension "file_browser"
require("telescope").load_extension "notify"
