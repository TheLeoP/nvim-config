local actions = require "telescope.actions"
local state = require "telescope.actions.state"
local utils = require "session_manager.utils"

require("project_nvim").setup {
  on_project_selection = function(prompt_bufnr)
    local entry = state.get_selected_entry()

    vim.cmd.tcd(entry.value)

    local session_name = utils.dir_to_session_filename(vim.loop.cwd())
    if not session_name:exists() then
      return true
    end

    require("session_manager").load_current_dir_session(true)
    return false
  end,
  find_files = "on_project_selection",
  detection_methods = { "pattern", "lsp" },
  ignore_lsp = { "null-ls", "emmet_ls" },
  show_hidden = true,
  scope_chdir = "tab",
  patterns = {
    "!>Documentos",
    "!>packages",
    "!>apps",
    "!>k6",
    "!>Lucho",
    "build.gradle",
    "package.json",
    ".git",
    "_darcs",
    ".hg",
    ".bzr",
    ".svn",
    "Makefile",
    "go.mod",
  },
}
