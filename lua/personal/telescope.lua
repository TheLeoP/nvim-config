local actions = require('telescope.actions')
local personal_actions = require('personal.fn_telescope')

require('telescope').setup {
  defaults = {
    color_devicons = true,
    borderchars = { '━', '┃', '━', '┃', '┏', '┓', '┛', '┗' },
    file_ignore_patterns = {
      '^tags$',
      '%.class$'
    },

    mappings = {
      i = {
        ["<C-f>"] = actions.send_to_qflist,
        ["<C-u>"] = false,
        ["<C-d>"] = false,
        -- ["<C-o>"] = personal_actions.ejecutar,
      },
      n = {
        -- ["o"] = personal_actions.ejecutar,
        ["q"] = actions.send_to_qflist,
        ["<c-{>"] = actions.close,
      },
    }
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = false,
      override_file_sorter = true,
      case_mode = "smart_case",
    },
    file_browser = {
      mappings = {
        i = {
          -- ["<C-o>"] = personal_actions.ejecutar,
        },
        n = {
          -- ["o"] = personal_actions.ejecutar,
        }
      }
    },
  }
}

require('telescope').load_extension('fzf')
require('telescope').load_extension('project')
require('telescope').load_extension('file_browser')
require('telescope').load_extension('notify')
