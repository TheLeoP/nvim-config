-- TODO: mover todo esto a /lua/util/telescope
local actions_state = require "telescope.actions.state"
local actions = require "telescope.actions"

local M = {}

function M.search_dotfiles()
  require("telescope.builtin").find_files {
    prompt_title = "< VimRC >",
    cwd = vim.fn.stdpath "config",
  }
end

function M.browse_trabajos()
  require("telescope").extensions.file_browser.file_browser {
    prompt_title = "< Browse Lucho >",
    cwd = vim.g.documentos,
  }
end

function M.search_trabajos()
  require("telescope.builtin").find_files {
    prompt_title = "< Buscar Lucho >",
    cwd = vim.g.documentos,
  }
end

function M.search_cd_files()
  vim.cmd "cd %:p:h"
  require("telescope.builtin").find_files {
    prompt_title = "< Buscar cd files >",
  }
end

function M.browse_cd_files()
  vim.cmd "cd %:p:h"
  require("telescope").extensions.file_browser.file_browser {
    prompt_title = "< Buscar cd files >",
  }
end

function M.seleccionar_materia(callback)
  local cerrar_y_llamar_callback = function(prompt_bufnr)
    local selected_entry = actions_state.get_selected_entry()
    local path = selected_entry.path .. "/"
    actions.close(prompt_bufnr)
    callback(path)
  end

  require("telescope").extensions.file_browser.file_browser {
    prompt_title = "< Seleccionar materia >",
    cwd = vim.g.documentos_u,
    attach_mappings = function(_, map)
      map("i", "<cr>", cerrar_y_llamar_callback)
      map("n", "<cr>", cerrar_y_llamar_callback)
      return true
    end,
  }
end

function M.search_nota_ciclo_actual_contenido()
  local callback = function(path)
    if path then
      local full_path = path .. "Apuntes/"

      require("telescope.builtin").live_grep {
        cwd = full_path,
        prompt_title = "Buscar nota por contenido",
      }
    else
      print "La entrada seleccionada no tiene path"
    end
  end

  require("personal.config.fn_telescope").seleccionar_materia(callback)
end

function M.search_nota_ciclo_actual_nombre()
  local callback = function(path)
    if path then
      local full_path = path .. "Apuntes/"

      require("telescope.builtin").find_files {
        cwd = full_path,
        prompt_title = "Buscar nota por nombre",
      }
    else
      print "La entrada seleccionada no tiene path"
    end
  end

  require("personal.config.fn_telescope").seleccionar_materia(callback)
end

function M.search_autoregistro_nombre()
  require("telescope").extensions.file_browser.file_browser {
    prompt_title = "< Buscar autoregistro por nombre >",
    cwd = vim.g.documentos .. "/Personal/autoregistro",
  }
end

function M.search_autoregistro_contenido()
  require("telescope.builtin").live_grep {
    prompt_title = "< Buscar autoregistro por contenido >",
    cwd = vim.g.documentos .. "/Personal/autoregistro",
  }
end

return M
