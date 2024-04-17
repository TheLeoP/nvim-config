return {
  {
    "TheLeoP/project.nvim",
    lazy = false,
    config = function()
      require("project_nvim").setup {
        detection_methods = { "lsp", "pattern" },
        ignore_lsp = { "null-ls", "emmet_ls", "lemminx", "lua-ls" },
        show_hidden = true,
        scope_chdir = "tab",
        patterns = {
          "!>Documentos U",
          "!>packages",
          "!>apps",
          "!>k6",
          "!>Lucho",
          "index.norg",
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
    end,
  },
  {
    "Shatur/neovim-session-manager",
    lazy = false,
    keys = {
      {
        "<leader><leader>ss",
        "<cmd>SessionManager save_current_session<cr>",
        mode = "n",
      },
      {
        "<leader><leader>sl",
        "<cmd>SessionManager load_session<cr>",
        mode = "n",
      },
    },
    config = function()
      local Path = require "plenary.path"
      require("session_manager").setup {
        sessions_dir = Path:new(vim.fn.stdpath "data", "sessions"),
        path_replacer = "__",
        colon_replacer = "++",
        autoload_mode = require("session_manager.config").AutoloadMode.Disabled,
        autosave_last_session = true,
        autosave_ignore_not_normal = true,
        autosave_ignore_dirs = {},
        autosave_ignore_filetypes = {
          "gitcommit",
        },
        autosave_ignore_buftypes = {},
        autosave_only_in_session = false,
        max_path_length = 80,
      }

      local config_group = vim.api.nvim_create_augroup("post-session", {})

      vim.api.nvim_create_autocmd({ "User" }, {
        pattern = "SessionLoadPost",
        group = config_group,
        callback = function()
          local cwd = vim.fn.getcwd()
          local exrc = vim.fs.find({ ".nvim.lua", ".nvimrc", ".exrc" }, { path = cwd, type = "file" })[1]
          if not exrc then return end
          local content = vim.secure.read(exrc)
          if not content then return end
          loadstring(content)()
        end,
      })
    end,
  },
  {
    "folke/flash.nvim",
    opts = {
      modes = {
        search = {
          enabled = false,
        },
        char = {
          enabled = false,
        },
      },
    },
    keys = {
      {
        "s",
        mode = { "n", "x", "o" },
        function() require("flash").jump() end,
        desc = "Flash",
      },
      {
        "S",
        mode = { "n", "o", "x" },
        function()
          local filetype = vim.bo[0].filetype
          local lang = vim.treesitter.language.get_lang(filetype)
          local ok, _parser = pcall(vim.treesitter.get_parser, 0, lang)
          if ok then
            require("flash").treesitter()
          else
            vim.notify(
              string.format(
                "There is no treesitter parser for filetype `%s`. Flash treesitter is deactivated",
                filetype
              )
            )
          end
        end,
        desc = "Flash Treesitter",
      },
      {
        "<c-s>",
        mode = { "c" },
        function() require("flash").toggle() end,
        desc = "Toggle Flash Search",
      },
    },
  },
  {
    "freddiehaddad/feline.nvim",
    config = function()
      local devicons = require "nvim-web-devicons"
      local navic = require "nvim-navic"
      local vi_mode = require "feline.providers.vi_mode"
      local Path = require "plenary.path"

      local custom_providers = {
        file = function(_, opts)
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

          return " " .. relative_path .. " " .. status, icon
        end,
        cwd = function() return vim.loop.cwd() end,
        navic = function(_, opts)
          local win_size = vim.api.nvim_win_get_width(0)
          local location = navic.get_location(opts)
          local location_size = vim.api.nvim_strwidth(location)
          local extra = #vim.fn.expand("%:t", false) + 4 -- 4 because ???
          if win_size < location_size + extra then
            local start = location_size + extra - win_size + 4 -- 4 because of "... "
            return "... " .. require("personal.util.general").str_multibyte_sub(location, start)
          else
            return location
          end
        end,
      }

      local statusline_components = {
        active = {
          {}, -- left
          {}, -- right
        },
      }

      table.insert(statusline_components.active[1], {
        provider = {
          name = "vi_mode",
          opts = {
            show_mode_name = true,
          },
        },
        hl = function()
          return {
            --- @type string
            name = vi_mode.get_mode_highlight_name(),
            --- @type string
            bg = vi_mode.get_mode_color(),
            fg = "bg",
            style = "bold",
          }
        end,
        left_sep = function()
          return {
            str = " ",
            hl = {
              --- @type string
              bg = vi_mode.get_mode_color(),
            },
            always_visible = true,
          }
        end,
        right_sep = function()
          return {
            str = " ",
            hl = {
              --- @type string
              bg = vi_mode.get_mode_color(),
            },
            always_visible = true,
          }
        end,
      })

      table.insert(statusline_components.active[1], {
        provider = "git_branch",
        --- @type string
        enabled = vim.b.gitsigns_head,
        hl = {
          fg = "lightblue",
        },
        left_sep = " ",
      })

      table.insert(statusline_components.active[1], {
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

      table.insert(statusline_components.active[1], {
        provider = {
          name = "file",
          opts = {
            length = 3,
          },
        },
      })

      table.insert(statusline_components.active[2], {
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
    dependencies = {
      "nvim-tree/nvim-web-devicons",
      "SmiteshP/nvim-navic",
    },
  },
  {
    "mbbill/undotree",
    init = function()
      if vim.fn.has "win32" == 1 then vim.g.undotree_DiffCommand = "FC" end
    end,
  },
  {
    "glacambre/firenvim",
    lazy = not vim.g.started_by_firenvim,
    init = function()
      vim.g.firenvim_config = {
        globalSettings = {
          alt = "all",
          ["<C-w>"] = "noop",
          ["<C-n>"] = "default",
          ["<C-t>"] = "default",
          takeover = "never",
        },
        localSettings = {
          [".*"] = {
            takeover = "never",
            priority = 999,
          },
        },
      }
    end,
    config = function()
      local group = vim.api.nvim_create_augroup("firenvim", { clear = true })
      vim.api.nvim_create_autocmd("UIEnter", {
        group = group,
        pattern = "*",
        callback = function()
          local event = vim.api.nvim_get_chan_info(vim.v.event.chan)
          if event == nil or event.client == nil then return end
          --- @type string
          local name = event.client.name
          if name == "Firenvim" then
            vim.o.laststatus = 0
            vim.o.winbar = nil
          end
        end,
      })
    end,
    build = function() vim.fn["firenvim#install"](0) end,
  },
}
