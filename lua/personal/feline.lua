local devicons = require "nvim-web-devicons"
local navic = require "nvim-navic"
local vi_mode = require "feline.providers.vi_mode"
local Path = require "plenary.path"

local custom_providers = {
  file = function(_, opts)
    local extension = vim.fn.expand("%:e", false, vim.g.lua_false)
    local filename = vim.fn.expand("%:t", false, vim.g.lua_false)
    local full_path = vim.fn.expand("%:p", false, vim.g.lua_false)
    local p = Path:new(full_path)
    local relative_p = Path:new(p:make_relative())

    local relative_path = relative_p:shorten(opts.length)

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

    return " " .. relative_path .. " " .. status, icon
  end,
  cwd = function()
    return vim.loop.cwd()
  end,
  tags = function()
    return vim.fn["gutentags#statusline"]()
  end,
  navic = function(_, opts)
    return navic.get_location(opts)
  end,
}

local statusline_components = {
  active = {
    {
      {
        provider = {
          name = "vi_mode",
          opts = {
            show_mode_name = true,
          },
        },
        hl = function()
          return {
            name = vi_mode.get_mode_highlight_name(),
            bg = vi_mode.get_mode_color(),
            fg = "bg",
            style = "bold",
          }
        end,
        left_sep = function()
          return {
            str = " ",
            hl = {
              bg = vi_mode.get_mode_color(),
            },
            always_visible = true,
          }
        end,
        right_sep = function()
          return {
            str = " ",
            hl = {
              bg = vi_mode.get_mode_color(),
            },
            always_visible = true,
          }
        end,
      },
      {
        provider = "git_branch",
        enabled = vim.b.gitsigns_head,
        hl = {
          fg = "lightblue",
        },
        left_sep = " ",
      },
      {
        provider = "cwd",
        left_sep = " ",
        right_sep = {
          str = " | ",
          hl = {
            fg = "white",
            bg = "bg",
          },
        },
      },
      {
        provider = {
          name = "file",
          opts = {
            length = 3,
          },
        },
      },
    },
    {
      {
        provider = "tags",
        left_sep = " ",
        right_sep = " ",
      },
      {
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
      },
    },
  },
}

local winbar_components = {
  active = {
    {
      {
        provider = "file_info",
        hl = {
          fg = "skyblue",
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

require("feline").setup {
  components = statusline_components,
  custom_providers = custom_providers,
}

require("feline").winbar.setup {
  components = winbar_components,
  custom_providers = custom_providers,
}
