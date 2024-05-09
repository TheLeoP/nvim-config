local function file_provider(_, opts)
  local devicons = require "nvim-web-devicons"
  local Path = require "plenary.path"

  local full_path = vim.fn.expand("%:p", false)

  local filename = vim.fn.expand("%:t", false)
  local extension = vim.fn.expand("%:e", false)
  local p = Path:new(full_path)
  local relative_p = Path:new(p:make_relative())

  ---@type string
  local relative_path = relative_p:shorten(opts.length)

  ---@type string ,string
  local iconStr, name = devicons.get_icon(filename, extension)
  local fg = name and vim.fn.synIDattr(vim.fn.hlID(name), "fg") or "white"

  local icon = {
    str = iconStr,
    hl = {
      fg = fg,
      bg = "bg",
    },
  }

  local status = vim.bo.readonly and "🔒" or vim.bo.modified and "●" or ""

  return (" %s %s"):format(relative_path, status), icon
end

local function navic_provider(_, opts)
  local navic = require "nvim-navic"
  local str_multibyte_sub = require("personal.util.general").str_multibyte_sub

  local win_size = vim.api.nvim_win_get_width(0)
  local location = navic.get_location(opts)
  local location_size = vim.api.nvim_strwidth(location)
  local extra = #vim.fn.expand("%:t", false) + 4 -- 4 because ???
  if win_size < location_size + extra then
    local start = location_size + extra - win_size + 4 -- 4 because of "... "
    return ("... %s"):format(str_multibyte_sub(location, start))
  else
    return location
  end
end

return {
  "freddiehaddad/feline.nvim",
  config = function()
    local navic = require "nvim-navic"
    local vi_mode = require "feline.providers.vi_mode"

    local custom_providers = {
      file = file_provider,
      cwd = vim.uv.cwd,
      navic = navic_provider,
    }

    local statusline_components = {
      active = {
        {}, -- left
        {}, -- right
      },
    }
    local left = statusline_components.active[1]
    local right = statusline_components.active[2]

    table.insert(left, {
      provider = {
        name = "vi_mode",
        opts = {
          show_mode_name = true,
        },
      },
      hl = function()
        return {
          name = vi_mode.get_mode_highlight_name(),
          bg = vi_mode.get_mode_color(), ---@type string
          fg = "bg",
          style = "bold",
        }
      end,
      left_sep = function()
        return {
          str = " ",
          hl = {
            bg = vi_mode.get_mode_color(), ---@type string
          },
          always_visible = true,
        }
      end,
      right_sep = function()
        return {
          str = " ",
          hl = {
            bg = vi_mode.get_mode_color(), ---@type string
          },
          always_visible = true,
        }
      end,
    })

    table.insert(left, {
      provider = "git_branch",
      enabled = vim.b.gitsigns_head, ---@type string
      hl = {
        fg = "lightblue",
      },
      left_sep = " ",
    })

    table.insert(left, {
      provider = "cwd",
      left_sep = " ",
      right_sep = {
        str = " | ",
        hl = {
          fg = "white",
          bg = "bg",
        },
      },
    })

    table.insert(left, {
      provider = {
        name = "file",
        opts = {
          length = 3,
        },
      },
    })

    table.insert(right, {
      provider = "file_type",
      hl = {
        fg = "bg",
        bg = "green",
      },
      left_sep = {
        str = " ",
        hl = {
          bg = "green",
        },
      },
      right_sep = {
        str = " ",
        hl = {
          bg = "green",
        },
      },
    })

    local winbar_components = {
      active = {
        {
          {
            provider = "file_info",
            hl = {
              fg = "orange",
              bg = "NONE",
              style = "bold",
            },
          },
          {
            provider = "navic",
            enabled = navic.is_available,
            left_sep = " ",
          },
        },
      },
      inactive = {
        {
          {
            provider = "file_info",
            hl = {
              fg = "white",
              bg = "NONE",
              style = "bold",
            },
          },
          {
            provider = "navic",
            enabled = navic.is_available,
            left_sep = " ",
          },
        },
      },
    }

    local gruvbox = {
      fg = "#fbf1c7",
      bg = "#32302f",
      black = "#1B1B1B",
      skyblue = "#83a598",
      cyan = "#83a597",
      green = "#98971a",
      oceanblue = "#458588",
      magenta = "#fb4934",
      orange = "#d65d0e",
      red = "#cc241d",
      violet = "#b16287",
      white = "#f9f5d7",
      yellow = "#d79921",
    }

    require("feline").setup {
      components = statusline_components,
      custom_providers = custom_providers,
      theme = gruvbox,
    }

    require("feline").winbar.setup {
      components = winbar_components,
      custom_providers = custom_providers,
    }
  end,
  dependencies = { "nvim-web-devicons", "nvim-navic" },
}
