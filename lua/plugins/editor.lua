return {
  {
    "nvim-telescope/telescope.nvim",
    cmd = "Telescope",
    keys = {
      { "<leader>ff", "<cmd>Telescope find_files hidden=true<cr>", mode = "n" },
      { "<leader>fg", "<cmd>Telescope git_branches<cr>", mode = "n" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", mode = "n" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", mode = "n" },
      { "<leader>fc", "<cmd>Telescope current_buffer_fuzzy_find<cr>", mode = "n" },
      { "<leader>fr", "<cmd>Telescope resume<cr>", mode = "n" },
      { "<leader>fwd", "<cmd>Telescope diagnostics<cr>", mode = "n" },

      {
        "<leader>fi",
        function()
          require("personal.util.telescope").search_nvim_config()
        end,
        mode = "n",
      },
      {
        "<leader>fl",
        function()
          require("personal.util.telescope").search_trabajos()
        end,
        mode = "n",
      },
      {
        "<leader>fL",
        function()
          require("personal.util.telescope").browse_trabajos()
        end,
        mode = "n",
      },
      {
        "<leader>fnc",
        function()
          require("personal.util.telescope").search_nota_ciclo_actual_contenido()
        end,
        mode = "n",
      },
      {
        "<leader>fnn",
        function()
          require("personal.util.telescope").search_nota_ciclo_actual_nombre()
        end,
        mode = "n",
      },
      {
        "<leader>fan",
        function()
          require("personal.util.telescope").search_autoregistro_nombre()
        end,
        mode = "n",
      },
      {
        "<leader>fac",
        function()
          require("personal.util.telescope").search_autoregistro_contenido()
        end,
        mode = "n",
      },
    },
    opts = {
      defaults = {
        color_devicons = true,
        path_display = {
          shorten = {
            len = 1,
            exclude = { 1, -1 },
          },
        },
        borderchars = { "━", "┃", "━", "┃", "┏", "┓", "┛", "┗" },
        file_ignore_patterns = {
          "^tags$",
          "%.class$",
          "%.jar$",
          "^miniconda3/",
          "^.git/",
          "lazy%-lock%.json",
          "node_modules",
        },

        mappings = {
          n = {
            ["q"] = function(...)
              require("telescope.actions").send_to_qflist(...)
            end,
            ["<c-{>"] = function(...)
              require("telescope.actions").close(...)
            end,
          },
        },
      },
      extensions = {
        fzf = {
          fuzzy = true,
          override_generic_sorter = true,
          override_file_sorter = true,
          case_mode = "smart_case",
        },
      },
    },
    config = function(_, opts)
      require("telescope").setup(opts)
      require("telescope").load_extension "fzf"
    end,
  },
  {
    "nvim-telescope/telescope-fzf-native.nvim",
    build = vim.g.make_cmd,
  },
  {
    "nvim-telescope/telescope-file-browser.nvim",
    keys = {
      {
        "<leader>fF",
        function()
          require("telescope").extensions.file_browser.file_browser()
        end,
        mode = "n",
      },
    },
  },
  {
    "nvim-telescope/telescope-live-grep-args.nvim",
    keys = {
      {
        "<leader>fs",
        function()
          require("telescope").extensions.live_grep_args.live_grep_args()
        end,
        mode = "n",
      },
    },
  },
  {
    "TheLeoP/project.nvim",
    lazy = false,
    dev = vim.fn.has "win32" == 0,
    keys = {
      {
        "<leader>fp",
        function()
          require("telescope").extensions.projects.projects()
        end,
        mode = "n",
      },
    },
    config = function()
      require("project_nvim").setup {
        on_project_selection = function()
          local state = require "telescope.actions.state"
          local utils = require "session_manager.utils"
          local entry = state.get_selected_entry()

          vim.cmd.tcd(entry.value)

          local session_name = utils.dir_to_session_filename { filename = vim.loop.cwd() }
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
          "!>Documentos U",
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
      require("telescope").load_extension "projects"
    end,
  },
  {
    "Shatur/neovim-session-manager",
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
    end,
  },
  {
    "NTBBloodbath/rest.nvim",
    config = true,
  },
  {
    "ggandor/flit.nvim",
    config = true,
    dependencies = {
      "ggandor/leap.nvim",
    },
  },
  {
    "ggandor/leap-spooky.nvim",
    config = true,
    dependencies = {
      "ggandor/leap.nvim",
    },
  },
  {
    "ggandor/leap.nvim",
    config = function()
      require("leap").add_default_mappings()
    end,
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

          if full_path:match "fern://" ~= nil then
            return " fern"
          end

          local filename = vim.fn.expand("%:t", false)
          local extension = vim.fn.expand("%:e", false)
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
        navic = function(_, opts)
          return navic.get_location(opts)
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
      })

      table.insert(statusline_components.active[1], {
        provider = "git_branch",
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
      "kyazdani42/nvim-web-devicons",
      "SmiteshP/nvim-navic",
    },
  },
  {
    lazy = false,
    "lambdalisue/fern.vim",
    init = function()
      vim.g["fern#renderer"] = "nvim-web-devicons"
      vim.g["glyph_palette#palette"] = require("fr-web-icons").palette()
    end,
  },
  {
    "TheLeoP/fern-renderer-web-devicons.nvim",
    dependencies = {
      "lambdalisue/fern.vim",
      "kyazdani42/nvim-web-devicons",
      "lambdalisue/glyph-palette.vim",
    },
  },
  {
    "lambdalisue/fern-hijack.vim",
    dependencies = {
      "lambdalisue/fern.vim",
    },
  },
  "mbbill/undotree",
  {
    "glacambre/firenvim",
    lazy = false,
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
          if event == nil or event.client == nil then
            return
          end
          local name = event.client.name
          if name == "Firenvim" then
            vim.o.laststatus = 0
            vim.o.winbar = nil
          end
        end,
      })
    end,
    build = function()
      vim.fn["firenvim#install"](0)
    end,
  },
  {
    "kevinhwang91/nvim-ufo",
    init = function()
      -- vim.o.foldcolumn = "1"
      vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
      vim.o.foldlevelstart = 99
      vim.o.foldenable = true
    end,
    config = function()
      require("ufo").setup()
      vim.keymap.set("n", "zR", require("ufo").openAllFolds)
      vim.keymap.set("n", "zM", require("ufo").closeAllFolds)
    end,
    dependencies = {
      "kevinhwang91/promise-async",
    },
  },
}
