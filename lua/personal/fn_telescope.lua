local action_state = require('telescope.actions.state')

local M = {}

function M.ejecutar(prompt_bufnr)
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

function M.search_dotfiles()
  require("telescope.builtin").find_files({
      prompt_title = "< VimRC >",
      cwd = vim.api.nvim_eval('$NVIMHOME'),
  })
end


function M.browse_trabajos()
  require("telescope.builtin").file_browser({
      prompt_title = "< Browse Lucho >",
      cwd = vim.g.documentos,
  })
end

function M.search_trabajos()
  require("telescope.builtin").find_files({
      prompt_title = "< Find Lucho >",
      cwd = vim.g.documentos,
  })
end

function M.search_cd_files()
  vim.cmd('cd %:p:h')
  require("telescope.builtin").find_files({
      prompt_title = "< Find cd files >",
  })
end

function M.browse_cd_files()
  vim.cmd('cd %:p:h')
  require("telescope.builtin").file_browser({
      prompt_title = "< Find cd files >",
  })
end

function M.search_autoregistro_emociones()
  require("telescope.builtin").find_files({
      prompt_title = "Search autoregistro emociones",
      cwd = vim.g.notas_emociones
  })
end

function M.browse_autoregistro_emociones()
  vim.cmd('cd ' .. vim.g.notas_emociones)
  require("telescope.builtin").file_browser({
      prompt_title = "Browse autoregistro emociones",
  })
end

function M.seleccionar_materia(callback)
  local llamar_callback_y_cerrar = function(prompt_bufnr)
    local selected_entry = action_state.get_selected_entry()
    callback(selected_entry, prompt_bufnr)
  end

  require('telescope.builtin').file_browser({
      prompt_title = '< Seleccionar materia >',
      cwd = vim.g.documentos_u,
      attach_mappings = function(_, map)
        map('i', '<cr>', llamar_callback_y_cerrar)
        map('n', '<cr>', llamar_callback_y_cerrar)
        return true
      end
  })
end

return M
