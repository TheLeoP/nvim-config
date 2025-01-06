local api = vim.api
local fs = vim.fs
local uv = vim.uv

local function file_provider()
  local status = vim.bo.readonly and "🔒" or vim.bo.modified and "●" or ""

  local full_path = vim.fn.expand("%:p", false)
  if full_path:match "^[^:]+:[/\\][/\\]" then
    local protocol, _full_path = full_path:match "^([^:]+):[/\\][/\\](.*)"
    full_path = _full_path or "" ---@type string
    if protocol == "oil" then
      full_path = require("oil.fs").posix_to_os_path(full_path)
    elseif protocol == "fugitive" then
      full_path = full_path:sub(2)
    end
  end
  full_path = fs.normalize(full_path)

  local relative_path = vim.fn.fnamemodify(full_path, ":.")
  relative_path = fs.normalize(relative_path)
  local cwd = uv.cwd() --[[@as string]]
  cwd = fs.normalize(cwd)
  local is_win = vim.fn.has "win32" == 1
  if relative_path == cwd or (is_win and relative_path:lower() == cwd:lower()) then relative_path = "." end

  if (not is_win and relative_path:sub(1, 1) ~= "/") or (is_win and not relative_path:match "^%u:/") then
    relative_path = "/" .. relative_path
  end
  return ("%s %s"):format(relative_path, status)
end

local function protocol_provider()
  local full_path = vim.fn.expand("%:p", false)
  local protocol = full_path:match "^([^:]+):[/\\][/\\]"
  return (" %s"):format(protocol)
end

local function icon_provider()
  local devicons = require "nvim-web-devicons"
  local filename = vim.fn.expand("%:t", false)
  local extension = vim.fn.expand("%:e", false)
  local icon_str, name = devicons.get_icon(filename, extension)
  local fg = name and vim.fn.synIDattr(vim.fn.hlID(name), "fg") or "white"
  local icon = {
    str = icon_str,
    hl = {
      fg = fg,
      bg = "bg",
    },
  }
  return " ", icon
end

local function navic_provider(_, opts)
  local navic = require "nvim-navic"
  local str_multibyte_sub = require("personal.util.general").str_multibyte_sub

  local win_size = api.nvim_win_get_width(0)
  local location = navic.get_location(opts)
  local location_size = api.nvim_strwidth(location)
  local extra = #vim.fn.expand("%:t", false) + 4 -- 4 because ???
  if win_size < location_size + extra then
    local start = location_size + extra - win_size + 4 -- 4 because of "... "
    return (" ... %s"):format(str_multibyte_sub(location, start))
  else
    return location
  end
end

local function git_branch_provider()
  local head = vim.b.gitsigns_head or vim.g.gitsigns_head
  return (" %s "):format(head)
end

local CTRL_S = vim.keycode "<C-S>"
local CTRL_V = vim.keycode "<C-V>"

local modes = setmetatable({
  ["n"] = " N ",
  ["v"] = " V ",
  ["V"] = " V-L ",
  [CTRL_V] = " V-B ",
  ["s"] = " S ",
  ["S"] = " S-L ",
  [CTRL_S] = " S-B ",
  ["i"] = " I ",
  ["R"] = " R ",
  ["c"] = " C ",
  ["r"] = " P ",
  ["!"] = " Sh ",
  ["t"] = " T ",
}, {
  __index = function() return " ? " end,
})

local function mode() return modes[vim.api.nvim_get_mode().mode] end

return {
  "freddiehaddad/feline.nvim",
  config = function()
    local navic = require "nvim-navic"
    local vi_mode = require "feline.providers.vi_mode"
    local feline = require "feline"

    local custom_providers = {
      file = file_provider,
      protocol = protocol_provider,
      icon = icon_provider,
      cwd = function()
        local cwd = uv.cwd()
        if not cwd then return "" end
        cwd = fs.normalize(cwd)
        return (" %s"):format(cwd)
      end,
      navic = navic_provider,
      git_branch_ = git_branch_provider,
      mode = mode,
      filetype = function() return (" %s "):format(vim.bo.filetype) end,
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
        name = "mode",
        opts = {},
      },
      hl = function()
        return {
          name = vi_mode.get_mode_highlight_name(),
          bg = vi_mode.get_mode_color(), ---@type string
          fg = "bg",
          style = "bold",
        }
      end,
    })

    table.insert(left, {
      provider = "git_branch_",
      enabled = function() return vim.b.gitsigns_head ~= nil or vim.g.gitsigns_head ~= nil end,
      hl = {
        fg = "lightblue",
      },
    })

    table.insert(left, {
      provider = "cwd",
      enabled = function() return uv.cwd() ~= nil end,
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
      },
    })
    table.insert(left, {
      provider = {
        name = "icon",
      },
    })
    table.insert(left, {
      provider = {
        name = "protocol",
      },
      enabled = function()
        local full_path = vim.fn.expand("%:p", false)
        return full_path:match "^[^:]+:[/\\][/\\]"
      end,
      hl = {
        fg = "lightblue",
      },
    })

    table.insert(right, {
      provider = "filetype",
      hl = {
        fg = "bg",
        bg = "green",
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
          },
        },
      },
    }

    local gruvbox = {
      dark = {
        fg = "#fbf1c7", -- GruboxFg0
        bg = "#32302f",
        black = "#1B1B1B",
        skyblue = "#83a598", -- GruvboxBlue
        cyan = "#83a598", -- GruvboxBlue
        green = "#98971a", -- NvimTreeExecFile
        oceanblue = "#458588", -- NvimTreeFolderIcon
        magenta = "#fb4934", -- GruvboxRed
        orange = "#d65d0e",
        red = "#cc241d", -- NvimTreeGitDeleted
        violet = "#b16286", -- NvimTreeGitRenamed
        white = "#f9f5d7",
        yellow = "#d79921", -- NvimTreeGitDirty
      },
      -- TODO: update to equivalent light color themes
      light = {
        fg = "#282828",
        bg = "#f1e9c0",
        black = "#1B1B1B",
        skyblue = "#076678",
        cyan = "#076678",
        green = "#98971a",
        oceanblue = "#458588",
        magenta = "#9d0006",
        orange = "#d65d0e",
        red = "#cc241d",
        violet = "#b16286",
        white = "#f9f5d7",
        yellow = "#d79921",
      },
    }
    local previous_bg = vim.o.background

    api.nvim_create_autocmd("Colorscheme", {
      callback = function()
        if vim.o.background == previous_bg then return end
        previous_bg = vim.o.background
        feline.use_theme(gruvbox[vim.o.background])
      end,
    })

    feline.setup {
      components = statusline_components,
      custom_providers = custom_providers,
      theme = gruvbox.dark,
      force_inactive = {},
    }

    feline.winbar.setup {
      components = winbar_components,
      custom_providers = custom_providers,
    }
  end,
  dependencies = { "nvim-web-devicons", "nvim-navic" },
}
