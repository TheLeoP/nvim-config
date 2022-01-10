local actions = require('telescope.actions')
local personal_actions = require('personal.fn_telescope')

require('telescope').setup {
  defaults = {
    color_devicons = true,

    file_previewer = require('telescope.previewers').vim_buffer_cat.new,
    grep_previewer = require('telescope.previewers').vim_buffer_vimgrep.new,
    qflist_previewer = require('telescope.previewers').vim_buffer_qflist.new,
    borderchars = { '━', '┃', '━', '┃', '┏', '┓', '┛', '┗' },

    mappings = {
      i = {
        ["<C-f>"] = actions.send_to_qflist,
        ["<C-o>"] = personal_actions.ejecutar,
      },
      n = {
        ["o"] = personal_actions.ejecutar,
        ["q"] = actions.send_to_qflist,
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
          ["<C-o>"] = personal_actions.ejecutar,
        },
        n = {
          ["o"] = personal_actions.ejecutar,
        }
      }
    },
  }
}

require('telescope').load_extension('fzf')
require('telescope').load_extension('project')
require('telescope').load_extension('file_browser')
require('telescope').load_extension('notify')
