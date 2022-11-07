local packer = require "packer"

local packer_augroup = vim.api.nvim_create_augroup("Packer", { clear = true })
vim.api.nvim_create_autocmd("BufWritePost", {
  command = "source <afile> | PackerCompile",
  group = packer_augroup,
  pattern = "packer.lua",
})

return packer.startup(function(use)
  -- Packer
  use "wbthomason/packer.nvim"

  use "nvim-lua/plenary.nvim"
  -- lsp
  use "williamboman/mason.nvim"

  use "williamboman/mason-lspconfig.nvim"

  use "jose-elias-alvarez/null-ls.nvim"

  use {
    "folke/neodev.nvim",
  }
  use {
    "neovim/nvim-lspconfig",
    config = function()
      require "personal.config.lsp"
    end,
  }
  use {
    "ray-x/lsp_signature.nvim",
    config = function()
      require "personal.config.signature"
    end,
  }
  use {
    "mfussenegger/nvim-jdtls",
  }
  use "jose-elias-alvarez/typescript.nvim"

  -- git
  use "tpope/vim-fugitive"
  use "tpope/vim-rhubarb"

  -- compilar con errores en quickfix list
  use "tpope/vim-dispatch"

  -- soporte para múltiples lenguajes
  use "sheerun/vim-polyglot"

  -- colorscheme
  use "tjdevries/colorbuddy.vim"
  use "tjdevries/gruvbuddy.nvim"

  -- surround actions
  use "tpope/vim-surround"

  -- acciones adicionales
  use "tpope/vim-commentary"
  use "tpope/vim-repeat"
  use "vim-scripts/ReplaceWithRegister"

  -- objects acidionales
  use "michaeljsmith/vim-indent-object"
  use "kana/vim-textobj-line"
  use "kana/vim-textobj-user"

  -- debugger para vim
  use {
    "mfussenegger/nvim-dap",
    config = function()
      require "personal.config.dap"
    end,
  }
  use {
    "rcarriga/nvim-dap-ui",
    config = function()
      require "personal.config.dapui"
    end,
  }
  -- lua en neovim debug server
  use "jbyuki/one-small-step-for-vimkind"

  -- test en vim
  use {
    "vim-test/vim-test",
    config = function()
      require "personal.config.vim-test"
    end,
  }

  -- coq
  use {
    "ms-jpq/coq_nvim",
    branch = "coq",
    config = function()
      require "personal.config.coq"
    end,
  }
  use {
    "ms-jpq/coq.artifacts",
    branch = "artifacts",
  }
  use {
    "ms-jpq/coq.thirdparty",
    branch = "3p",
  }

  -- telescope
  use {
    "nvim-telescope/telescope.nvim",
    config = function()
      require "personal.config.telescope"
    end,
  }
  use {
    "nvim-telescope/telescope-fzf-native.nvim",
    run = vim.g.make_cmd,
  }
  -- extensiones telescope
  use "nvim-telescope/telescope-file-browser.nvim"

  use {
    "ahmedkhalf/project.nvim",
    config = function()
      require "personal.config.project"
    end,
  }
  use "nvim-telescope/telescope-live-grep-args.nvim"

  -- íconos en nvim
  use {
    "kyazdani42/nvim-web-devicons",
    config = function()
      require "personal.config.devicons"
    end,
  }

  -- teesitter
  use {
    "nvim-treesitter/nvim-treesitter",
    run = ":TSUpdate",
    config = function()
      require "personal.config.treesitter"
    end,
  }
  use {
    "nvim-treesitter/nvim-treesitter-textobjects",
  }

  -- gps para statusline usando treesitter
  use {
    "SmiteshP/nvim-navic",
    config = function()
      require "personal.config.nvim-navic"
    end,
  }

  -- resalta palabra bajo el cursor
  use "RRethy/vim-illuminate"

  -- extender la capacidad de ctrl-a
  use "monaqa/dial.nvim"

  -- dashboard
  use {
    "glepnir/dashboard-nvim",
    config = function()
      require "personal.config.dashboard"
    end,
  }

  -- GUI para vim.ui.input y vim.ui.select
  use {
    "stevearc/dressing.nvim",
    config = function()
      require "personal.config.dressing"
    end,
  }
  use {
    "j-hui/fidget.nvim",
    config = function()
      require "personal.config.fidget"
    end,
  }

  -- GUI para vim.notify
  use {
    "rcarriga/nvim-notify",
    config = function()
      require "personal.config.notify"
    end,
  }

  -- mejoran la carga de neovim
  use "lewis6991/impatient.nvim"

  -- diagramas en nvim
  use {
    "jbyuki/venn.nvim",
    config = function()
      require "personal.config.venn"
    end,
  }

  -- soporte para REST request
  use {
    "NTBBloodbath/rest.nvim",
    config = function()
      require "personal.config.rest"
    end,
  }

  -- mejor soporte para terminal
  use "norcalli/nvim-terminal.lua"

  -- db
  use "tpope/vim-dadbod"
  use "kristijanhusak/vim-dadbod-ui"

  -- visualizar colores en hex
  use {
    "norcalli/nvim-colorizer.lua",
    config = function()
      require "personal.config.colorizer"
    end,
  }

  -- soporte para tags
  use {
    "ludovicchabant/vim-gutentags",
    opt = true,
    config = function()
      require "personal.config.gutentags"
    end,
  }

  -- ayuda visual para indentación
  use {
    "lukas-reineke/indent-blankline.nvim",
    config = function()
      require "personal.config.blankline"
    end,
  }

  -- gisigns
  use {
    "lewis6991/gitsigns.nvim",
    config = function()
      require "personal.config.gitsigns"
    end,
  }

  -- sudo
  use {
    "lambdalisue/suda.vim",
    config = function()
      require "personal.config.suda"
    end,
  }

  use "windwp/nvim-ts-autotag"

  use "JoosepAlviste/nvim-ts-context-commentstring"

  use "kevinhwang91/promise-async"
  use {
    "kevinhwang91/nvim-ufo",
    config = function()
      require "personal.config.ufo"
    end,
  }

  use {
    "ThePrimeagen/refactoring.nvim",
    config = function()
      require "personal.config.refactoring"
    end,
  }

  use {
    "jedrzejboczar/possession.nvim",
    config = function()
      require "personal.config.possession"
    end,
  }

  use {
    "sindrets/diffview.nvim",
    config = function()
      require "personal.config.diffview"
    end,
  }

  use {
    "ggandor/leap.nvim",
    config = function()
      require "personal.config.leap"
    end,
  }

  -- linea de estado
  use {
    "feline-nvim/feline.nvim",
    config = function()
      require "personal.config.feline"
    end,
  }

  use "nvim-treesitter/playground"

  use {
    "lambdalisue/fern.vim",
    config = function()
      require "personal.config.fern"
    end,
  }

  use "ellisonleao/gruvbox.nvim"
  use "lambdalisue/fern-hijack.vim"

  use "TheLeoP/fern-renderer-web-devicons.nvim"
end)
