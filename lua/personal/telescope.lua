local actions = require('telescope.actions')
local personal_actions = require('personal.fn_telescope')

require('telescope').setup {
  defaults = {
    file_sorter = require('telescope.sorters').get_fzy_sorter ,
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
        ["<C-o>"] = personal_actions.ejecutar,
      },
    }
  },
  extensions = {
    fzf = {
      fuzzy = true,
      override_generic_sorter = false,
      override_file_sorter = true,
      case_mode = "smart_case",
    }
  }
}

require('telescope').load_extension('fzf')

local M = {}
M.search_dotfiles = function()
  require("telescope.builtin").find_files({
      prompt_title = "< VimRC >",
      cwd = '~/AppData/Local/nvim/',
  })
end

M.browse_trabajos = function()
  require("telescope.builtin").file_browser({
      prompt_title = "< Browse Lucho >",
      cwd = 'D:/Lucho/',
  })
end

M.search_trabajos = function()
  require("telescope.builtin").find_files({
      prompt_title = "< Find Lucho >",
      cwd = 'D:/Lucho/',
  })
end

M.search_cd_files = function()
  require("telescope.builtin").find_files({
      prompt_title = "< Find cd files >",
      cwd = (string.gsub(vim.api.nvim_eval("expand('%:p:h')"), "\\", "/")),
  })
end

M.browse_cd_files = function()
  require("telescope.builtin").file_browser({
      prompt_title = "< Find cd files >",
      cwd = (string.gsub(vim.api.nvim_eval("expand('%:p:h')"), "\\", "/")),
  })
end

return M
