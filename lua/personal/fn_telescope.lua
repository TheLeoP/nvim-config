local action_state = require('telescope.actions.state')
local trabajos

if vim.fn.has("win32") == 1 then
  trabajos = 'D:/Lucho/'
else
  trabajos = vim.api.nvim_eval('$HOME') .. '/Documentos'
end

local M = {}

M.ejecutar = function(prompt_bufnr)
  local entry = action_state.get_selected_entry(prompt_bufnr)

  if not entry then
    print("[telescope] Nothing currently selected")
    return
  end

  local filename = entry.path or entry.filename
  filename = "\"" .. filename .. "\""
  filename = filename:gsub('\\\\','\\')

  os.execute('explorer.exe ' .. filename)
end

M.search_dotfiles = function()
  require("telescope.builtin").find_files({
      prompt_title = "< VimRC >",
      cwd = vim.api.nvim_eval('$NVIMHOME'),
  })
end


M.browse_trabajos = function()
  require("telescope.builtin").file_browser({
      prompt_title = "< Browse Lucho >",
      cwd = trabajos,
  })
end

M.search_trabajos = function()
  require("telescope.builtin").find_files({
      prompt_title = "< Find Lucho >",
      cwd = trabajos,
  })
end

M.search_cd_files = function()
  vim.cmd('cd %:p:h')
  require("telescope.builtin").find_files({
      prompt_title = "< Find cd files >",
  })
end

M.browse_cd_files = function()
  vim.cmd('cd %:p:h')
  require("telescope.builtin").file_browser({
      prompt_title = "< Find cd files >",
  })
end

return M
