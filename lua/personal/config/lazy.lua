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

require("lazy").setup {
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
  -- surround actions
  "tpope/vim-surround",
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
      "jbyuki/one-small-step-for-vimkind",
    },
    config = function()
      require "personal.config.dap"
    end,
  },
  -- test en vim
  {
    "vim-test/vim-test",
    config = function()
      require "personal.config.vim-test"
    end,
  },
  -- coq
  {
    "ms-jpq/coq_nvim",
    branch = "coq",
    config = function()
      require "personal.config.coq"
    end,
  },
  {
    "ms-jpq/coq.artifacts",
    branch = "artifacts",
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
        "ahmedkhalf/project.nvim",
        config = function()
          require "personal.config.project"
        end,
      },
      "nvim-telescope/telescope-live-grep-args.nvim",
      "nvim-treesitter/nvim-treesitter",
      "neovim/nvim-lspconfig",
      "kyazdani42/nvim-web-devicons",
      "rcarriga/nvim-notify",
      "jedrzejboczar/possession.nvim",
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
  -- ayuda visual para indentación
  {
    "lukas-reineke/indent-blankline.nvim",
    config = function()
      require "personal.config.blankline"
    end,
  },
  -- sudo
  {
    "lambdalisue/suda.vim",
    config = function()
      require "personal.config.suda"
    end,
  },
  {
    "kevinhwang91/nvim-ufo",
    config = function()
      require "personal.config.ufo"
    end,
    dependencies = {
      "kevinhwang91/promise-async",
    },
  },
  {
    "theprimeagen/refactoring.nvim",
    config = function()
      require "personal.config.refactoring"
    end,
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-treesitter/nvim-treesitter",
    },
  },
  {
    "jedrzejboczar/possession.nvim",
    config = function()
      require "personal.config.possession"
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
    "ggandor/leap.nvim",
    config = function()
      require "personal.config.leap"
    end,
  },
  {
    "feline-nvim/feline.nvim",
    config = function()
      require "personal.config.feline"
    end,
    dependencies = {
      "kyazdani42/nvim-web-devicons",
      "SmiteshP/nvim-navic",
    },
  },
  {
    "lambdalisue/fern.vim",
  },
  {
    "kyazdani42/nvim-web-devicons",
    config = function()
      require "personal.config.devicons"
    end,
  },
  {
    "TheLeoP/fern-renderer-web-devicons.nvim",
    config = function()
      require "personal.config.fern"
    end,
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
    config = function()
      require "personal.config.matchup"
    end,
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
    },
  },
  "mbbill/undotree",
}
