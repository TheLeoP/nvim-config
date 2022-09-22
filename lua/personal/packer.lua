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

  -- git
  use "tpope/vim-fugitive"
  use "tpope/vim-rhubarb"

  -- compilar con errores en quickfix list
  use "tpope/vim-dispatch"
  use "radenling/vim-dispatch-neovim"

  -- soporte para múltiples lenguajes
  use "sheerun/vim-polyglot"

  -- colorscheme
  use "tjdevries/colorbuddy.vim"
  use "tjdevries/gruvbuddy.nvim"

  -- linea de estado
  use {
    "feline-nvim/feline.nvim",
    config = function()
      require "personal.feline"
    end,
  }

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
      require "personal.dap"
    end,
  }
  use {
    "rcarriga/nvim-dap-ui",
    config = function()
      require "personal.dapui"
    end,
  }
  -- lua en neovim debug server
  use "jbyuki/one-small-step-for-vimkind"

  -- test en vim
  use {
    "vim-test/vim-test",
    config = function()
      require "personal.vim-test"
    end,
  }

  -- lsp
  use {
    "neovim/nvim-lspconfig",
    config = function()
      require "personal.lsp"
    end,
  }
  use {
    "ray-x/lsp_signature.nvim",
    config = function()
      require "personal.signature"
    end,
  }
  use {
    "mfussenegger/nvim-jdtls",
  }
  use {
    "folke/lua-dev.nvim",
  }
  use {
    "williamboman/mason.nvim",
    config = function()
      require "personal.mason"
    end,
  }
  use {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require "personal.mason-lspconfig"
    end,
  }
  use "jose-elias-alvarez/typescript.nvim"

  -- coq
  use {
    "ms-jpq/coq_nvim",
    commit = "84ec5faf2aaf49819e626f64dd94f4e71cf575bc",
    branch = "coq",
    config = function()
      require "personal.coq"
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
  use "nvim-lua/popup.nvim"
  use "nvim-lua/plenary.nvim"
  use {
    "nvim-telescope/telescope.nvim",
    config = function()
      require "personal.telescope"
    end,
  }
  use {
    "nvim-telescope/telescope-fzf-native.nvim",
    run = vim.g.make_cmd,
  }
  -- extensiones telescope
  use {
    "nvim-telescope/telescope-file-browser.nvim",
    config = function()
      require "personal.project"
    end,
  }
  use "ahmedkhalf/project.nvim"
  use "nvim-telescope/telescope-live-grep-args.nvim"

  -- íconos en nvim
  use {
    "kyazdani42/nvim-web-devicons",
    config = function()
      require "personal.devicons"
    end,
  }

  -- teesitter
  use {
    "nvim-treesitter/nvim-treesitter",
    run = ":TSUpdate",
    config = function()
      require "personal.treesitter"
    end,
  }
  use {
    "nvim-treesitter/nvim-treesitter-textobjects",
  }

  -- gps para statusline usando treesitter
  use {
    "SmiteshP/nvim-navic",
    config = function()
      require "personal.nvim-navic"
    end,
  }

  -- mejor integración con netrw
  use "tpope/vim-vinegar"

  -- resalta palabra bajo el cursor
  use "RRethy/vim-illuminate"

  -- extender la capacidad de i_ctrl-a
  use "monaqa/dial.nvim"

  -- dashboard
  use {
    "glepnir/dashboard-nvim",
    config = function()
      require "personal.dashboard"
    end,
  }

  -- GUI para vim.ui.input y vim.ui.select
  use {
    "stevearc/dressing.nvim",
    config = function()
      require "personal.dressing"
    end,
  }
  use {
    "j-hui/fidget.nvim",
    config = function()
      require "personal.fidget"
    end,
  }

  -- GUI para vim.notify
  use {
    "rcarriga/nvim-notify",
    config = function()
      require "personal.notify"
    end,
  }

  -- mejoran la carga de neovim
  use "lewis6991/impatient.nvim"
  use "nathom/filetype.nvim"

  -- diagramas en nvim
  use {
    "jbyuki/venn.nvim",
    config = function()
      require "personal.venn"
    end,
  }

  -- soporte para REST request
  use {
    "NTBBloodbath/rest.nvim",
    commit = "e5f68db73276c4d4d255f75a77bbe6eff7a476ef",
    config = function()
      require "personal.rest"
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
      require "personal.colorizer"
    end,
  }

  -- soporte para tags
  use {
    "ludovicchabant/vim-gutentags",
    opt = true,
    config = function()
      require "personal.gutentags"
    end,
    opt = true,
  }

  -- ayuda visual para indentación
  use {
    "lukas-reineke/indent-blankline.nvim",
    config = function()
      require "personal.blankline"
    end,
  }

  -- gisigns
  use {
    "lewis6991/gitsigns.nvim",
    config = function()
      require "personal.gitsigns"
    end,
  }

  -- sudo
  use {
    "lambdalisue/suda.vim",
    config = function()
      require "personal.suda"
    end,
  }

  use "jose-elias-alvarez/null-ls.nvim"

  use "antoinemadec/FixCursorHold.nvim"

  use "windwp/nvim-ts-autotag"

  use "JoosepAlviste/nvim-ts-context-commentstring"

  use "kevinhwang91/promise-async"
  use {
    "kevinhwang91/nvim-ufo",
    config = function()
      require "personal.ufo"
    end,
  }

  use {
    "ThePrimeagen/refactoring.nvim",
    config = function()
      require "personal.refactoring"
    end,
  }

  use {
    "jedrzejboczar/possession.nvim",
    config = function()
      require "personal.possession"
    end,
  }

  use {
    "sindrets/diffview.nvim",
    config = function()
      require "personal.diffview"
    end,
  }

  use {
    "ggandor/leap.nvim",
    config = function()
      require'personal.leap'
    end
  }
  use {
    "ggandor/flit.nvim",
    config = function()
      require'personal.flit'
    end
  }
end)
