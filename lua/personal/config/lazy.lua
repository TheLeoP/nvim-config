vim.g.mapleader = " "
vim.g.maplocalleader = ","

local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "--single-branch",
    "https://github.com/folke/lazy.nvim.git",
    lazypath,
  }
end
vim.opt.runtimepath:prepend(lazypath)

require("lazy").setup({
  -- colorscheme
  {
    "ellisonleao/gruvbox.nvim",
    lazy = false,
    priority = 1000,
    config = function()
      vim.cmd.colorscheme "gruvbox"
    end,
  },
  -- dashboard
  {
    "glepnir/dashboard-nvim",
    config = function()
      require "personal.config.dashboard"
    end,
  },
  -- GUI para vim.ui.input y vim.ui.select
  {
    "stevearc/dressing.nvim",
    config = function()
      require "personal.config.dressing"
    end,
  },
  -- lsp
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "b0o/schemastore.nvim",
      "williamboman/mason.nvim",
      "williamboman/mason-lspconfig.nvim",
      "jose-elias-alvarez/null-ls.nvim",
      "folke/neodev.nvim",
      "mfussenegger/nvim-jdtls",
      "jose-elias-alvarez/typescript.nvim",
      "nvim-telescope/telescope.nvim",
      "SmiteshP/nvim-navic",
    },
    config = function()
      require "personal.config.lsp"
    end,
  },
  {
    "j-hui/fidget.nvim",
    config = function()
      require "personal.config.fidget"
    end,
    dependencies = {
      "neovim/nvim-lspconfig",
    },
  },
  {
    "SmiteshP/nvim-navic",
    config = function()
      require "personal.config.nvim-navic"
    end,
    dependencies = {
      "neovim/nvim-lspconfig",
    },
  },
  {
    "RRethy/vim-illuminate",
    dependencies = {
      "neovim/nvim-lspconfig",
    },
  },
  {
    "ray-x/lsp_signature.nvim",
    config = function()
      require "personal.config.signature"
    end,
  },
  -- git
  "tpope/vim-fugitive",
  "tpope/vim-rhubarb",
  {
    "lewis6991/gitsigns.nvim",
    config = function()
      require "personal.config.gitsigns"
    end,
  },
  -- compilar con errores en quickfix list
  "tpope/vim-dispatch",
  -- configurar indent automáticamente
  "tpope/vim-sleuth",
  {
    "tpope/vim-surround",
    init = function()
      vim.g.surround_no_mappings = 1
    end,
    config = function()
      require "personal.config.surround"
    end,
  },
  -- acciones adicionales
  "tpope/vim-commentary",
  "tpope/vim-repeat",
  "vim-scripts/ReplaceWithRegister",
  -- objects acidionales
  {
    "kana/vim-textobj-line",
    dependencies = {
      "kana/vim-textobj-user",
    },
  },
  -- debugger para vim
  {
    "rcarriga/nvim-dap-ui",
    dependencies = {
      "mfussenegger/nvim-dap",
      "mfussenegger/nvim-dap-python",
      "jbyuki/one-small-step-for-vimkind",
    },
    config = function()
      require "personal.config.dap"
    end,
  },
  -- test en vim
  {
    "vim-test/vim-test",
    init = function()
      vim.g["test#java#runner"] = "gradletest"
      vim.g["test#strategy"] = "dispatch"
    end,
  },
  -- coq
  {
    "ms-jpq/coq_nvim",
    branch = "coq",
    init = function()
      vim.o.completeopt = "menuone,noselect,noinsert"
      vim.o.showmode = false

      vim.g.coq_settings = {
        auto_start = "shut-up",
        keymap = {
          recommended = false,
          jump_to_mark = "<m-,>",
        },
        clients = {
          snippets = {
            warn = {},
          },
          paths = {
            path_seps = {
              "/",
            },
          },
          buffers = {
            match_syms = false,
          },
          third_party = {
            enabled = false,
          },
          lsp = {
            weight_adjust = 1,
          },
        },
        display = {
          ghost_text = {
            enabled = true,
          },
          -- preview = {
          --   border = vim.g.lsp_borders,
          -- },
          pum = {
            fast_close = false,
          },
        },
        match = {
          unifying_chars = {
            "-",
            "_",
          },
        },
        limits = {
          completion_auto_timeout = 1.0,
          completion_manual_timeout = 1.0,
        },
      }
    end,
    config = function()
      require "personal.config.coq"
    end,
  },
  {
    "github/copilot.vim",
    init = function()
      vim.g.copilot_no_tab_map = vim.v["true"]
    end,
    config = function()
      require "personal.config.copilot"
    end,
  },
  -- telescope
  {
    "nvim-telescope/telescope.nvim",
    config = function()
      require "personal.config.telescope"
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = vim.g.make_cmd,
      },
      "nvim-telescope/telescope-file-browser.nvim",
      {
        "TheLeoP/project.nvim",
        dev = vim.fn.has "win32" == 0,
        config = function()
          require "personal.config.project"
        end,
      },
      "nvim-telescope/telescope-live-grep-args.nvim",
      "nvim-treesitter/nvim-treesitter",
      "neovim/nvim-lspconfig",
      "kyazdani42/nvim-web-devicons",
      "rcarriga/nvim-notify",
    },
  },
  -- teesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
    config = function()
      require "personal.config.treesitter"
    end,
    dependencies = {
      {
        "folke/twilight.nvim",
        config = function()
          require "personal.config.twilight"
        end,
      },
      "nvim-treesitter/nvim-treesitter-textobjects",
      "nvim-treesitter/playground",
      "windwp/nvim-ts-autotag",
      "JoosepAlviste/nvim-ts-context-commentstring",
    },
  },
  -- GUI para vim.notify
  {
    "rcarriga/nvim-notify",
    config = function()
      require "personal.config.notify"
    end,
  },
  -- soporte para REST request
  {
    "NTBBloodbath/rest.nvim",
    config = function()
      require "personal.config.rest"
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
  -- db
  {
    "kristijanhusak/vim-dadbod-ui",
    init = function()
      vim.g.db_ui_force_echo_notifications = 1
      vim.g.db_ui_show_database_icon = 1
    end,
    dependencies = {
      "tpope/vim-dadbod",
    },
  },
  -- visualizar colores en hex
  {
    "NvChad/nvim-colorizer.lua",
    config = function()
      require "personal.config.colorizer"
    end,
  },
  -- sudo
  {
    "lambdalisue/suda.vim",
    init = function()
      vim.g["suda#prompt"] = "Contraseña: "

      if vim.fn.has "win32" ~= 1 then
        vim.g.suda_smart_edit = 1
      end
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
      require "personal.config.ufo"
    end,
    dependencies = {
      "kevinhwang91/promise-async",
    },
  },
  {
    "theprimeagen/refactoring.nvim",
    dev = vim.fn.has "win32" == 0,
    config = function()
      require "personal.config.refactoring"
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
  },
  {
    "Shatur/neovim-session-manager",
    config = function()
      require "personal.config.session_manager"
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
  {
    "sindrets/diffview.nvim",
    config = function()
      require "personal.config.diffview"
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "kyazdani42/nvim-web-devicons",
    },
  },
  {
    "ggandor/flit.nvim",
    config = function()
      require "personal.config.flit"
    end,
    dependencies = {
      "ggandor/leap.nvim",
    },
  },
  {
    "ggandor/leap-spooky.nvim",
    config = function()
      require "personal.config.leap-spooky"
    end,
    dependencies = {
      "ggandor/leap.nvim",
    },
  },
  {
    "ggandor/leap.nvim",
    config = function()
      require "personal.config.leap"
    end,
  },
  {
    "freddiehaddad/feline.nvim",
    config = function()
      require "personal.config.feline"
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
    "kyazdani42/nvim-web-devicons",
    config = function()
      require "personal.config.devicons"
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
  {
    "andymass/vim-matchup",
    init = function()
      vim.g.loaded_matchit = 1
      vim.g.matchup_matchparen_offscreen = {
        method = "popup",
      }
    end,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
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
      require "personal.config.firenvim"
    end,
    build = function()
      vim.fn["firenvim#install"](0)
    end,
  },
  {
    "chomosuke/term-edit.nvim",
    lazy = false,
    config = function()
      require "personal.config.term-edit"
    end,
  },
  {
    "danymat/neogen",
    config = function()
      require "personal.config.neogen"
    end,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
  },
  {
    "nvim-neorg/neorg",
    build = ":Neorg sync-parsers",
    opts = {
      load = {
        ["core.defaults"] = {}, -- Loads default behaviour
        ["core.norg.concealer"] = {}, -- Adds pretty icons to your documents
        ["core.norg.dirman"] = { -- Manages Neorg workspaces
          config = {
            workspaces = {
              notes = "~/notes",
              work = "~/work",
            },
            default_workspace = "notes",
          },
        },
      },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
  },
}, {
  dev = {
    path = vim.g.documentos .. "/Personal",
  },
  install = {
    colorscheme = { "gruvbox" },
  },
  ui = {
    icons = {
      cmd = "⌘",
      config = "🛠",
      event = "📅",
      ft = "📂",
      init = "⚙",
      keys = "🗝",
      plugin = "🔌",
      runtime = "💻",
      source = "📄",
      start = "🚀",
      task = "📌",
      lazy = "💤 ",
    },
  },
})
