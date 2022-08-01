local packer = require('packer')

local packer_augroup = vim.api.nvim_create_augroup('Packer', { clear = true })
vim.api.nvim_create_autocmd(
  'BufWritePost',
    {
      command = 'source <afile> | PackerCompile',
      group = packer_augroup,
      pattern = 'packer.lua'
    })

return packer.startup(function(use)

  -- Packer
  use 'wbthomason/packer.nvim'

  -- git
  use 'tpope/vim-fugitive'
  use 'tpope/vim-rhubarb'

  -- compilar con errores en quickfix list
  use 'tpope/vim-dispatch'
  use 'radenling/vim-dispatch-neovim'

  -- soporte para múltiples lenguajes
  use 'sheerun/vim-polyglot'

  -- colorscheme
  use 'tjdevries/colorbuddy.vim'
  use 'tjdevries/gruvbuddy.nvim'
  use 'Murtaza-Udaipurwala/gruvqueen'

  -- linea de estado
  use {
    'itchyny/lightline.vim',
    config = function() require('personal.lightline') end
  }

  -- surround actions
  use 'tpope/vim-surround'

  -- acciones adicionales
  use 'tpope/vim-commentary'
  use 'tpope/vim-repeat'
  use 'vim-scripts/ReplaceWithRegister'

  -- objects acidionales
  use 'michaeljsmith/vim-indent-object'
  use 'kana/vim-textobj-line'
  use 'kana/vim-textobj-user'

  -- debugger para vim
  use {
    'mfussenegger/nvim-dap',
    config = function() require('personal.dap') end
  }
  use {
    'rcarriga/nvim-dap-ui',
    config = function() require('personal.dapui') end
  }
  -- lua en neovim debug server
  use 'jbyuki/one-small-step-for-vimkind'

  -- test en vim
  use {
    'vim-test/vim-test',
    config = function() require('personal.vim-test') end
  }

  -- lsp
  use {
    'neovim/nvim-lspconfig',
    config = function() require('personal.lsp') end
  }
  use {
    'ray-x/lsp_signature.nvim',
    config = function() require('personal.signature') end
  }
  use {
    'mfussenegger/nvim-jdtls',
  }

  -- coq
  use {
    'ms-jpq/coq_nvim',
    branch = 'coq',
    config = function() require('personal.coq') end
  }
  use {
    'ms-jpq/coq.artifacts',
    branch = 'artifacts'
  }
  use {
    'ms-jpq/coq.thirdparty',
    branch = '3p'
  }

  -- telescope
  use 'nvim-lua/popup.nvim'
  use 'nvim-lua/plenary.nvim'
  use {
    'nvim-telescope/telescope.nvim',
    config = function() require('personal.telescope') end
  }
  use {
    'nvim-telescope/telescope-fzf-native.nvim',
    run = vim.g.make_cmd
  }
  -- extensiones telescope
  use 'nvim-telescope/telescope-project.nvim'
  use 'nvim-telescope/telescope-file-browser.nvim'

  -- íconos en nvim
  use {
    'kyazdani42/nvim-web-devicons',
    config = function() require('personal.devicons') end
  }

  -- teesitter
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
    config = function() require('personal.treesitter') end
  }
  use {
    'nvim-treesitter/nvim-treesitter-textobjects',
  }
  use {
    'RRethy/nvim-treesitter-textsubjects',
    config = function() require('personal.treesitter-textsubjects') end
  }

  -- gps para statusline usando treesitter
  use {
    'SmiteshP/nvim-gps',
    config = function() require('personal.nvim-gps') end
  }

  -- mejor integración con netrw
  use 'tpope/vim-vinegar'

  -- resalta palabra bajo el cursor
  use 'RRethy/vim-illuminate'

  -- extender la capacidad de i_ctrl-a
  use 'monaqa/dial.nvim'

  -- dashboard
  use {
   'glepnir/dashboard-nvim',
    commit = 'd87007a5ec91f5d6fba1d62b40a767e3cb67878f',
    config = function() require('personal.dashboard') end
  }

  -- lsp diagnostics
  use 'nvim-lua/lsp-status.nvim'

  -- GUI para vim.ui.input y vim.ui.select
  use {
    'stevearc/dressing.nvim',
    config = function() require('personal.dressing') end
  }

  -- GUI para vim.notify
  use {
    'rcarriga/nvim-notify',
    config = function() require('personal.notify') end
  }

  -- mejoran la carga de neovim
  use 'lewis6991/impatient.nvim'
  use 'nathom/filetype.nvim'

  -- diagramas en nvim
  use {
    'jbyuki/venn.nvim',
    config = function() require('personal.venn') end
  }

  -- soporte para REST request
  use {
    'NTBBloodbath/rest.nvim',
    commit = "e5f68db73276c4d4d255f75a77bbe6eff7a476ef",
    config = function() require('personal.rest') end
  }

  -- mejor soporte para terminal
  use 'norcalli/nvim-terminal.lua'

  -- db
  use 'tpope/vim-dadbod'
  use 'kristijanhusak/vim-dadbod-ui'

  -- visualizar colores en hex
  use {
    'norcalli/nvim-colorizer.lua',
    config = function() require('personal.colorizer') end
  }

  -- soporte para tags
  use {
    'ludovicchabant/vim-gutentags',
    config = function() require('personal.gutentags') end
  }

  -- ayuda visual para indentación
  use {
    'lukas-reineke/indent-blankline.nvim',
    config = function() require('personal.blankline') end
  }

  -- gisigns
  use {
    'lewis6991/gitsigns.nvim',
    config = function() require('personal.gitsigns') end
  }

  -- sudo
  use {
    'lambdalisue/suda.vim',
    config = function() require('personal.suda') end
  }

  use 'jose-elias-alvarez/null-ls.nvim'

  use 'antoinemadec/FixCursorHold.nvim'

  use {
    'glacambre/firenvim',
    run = function() vim.fn['firenvim#install'](0) end
  }

end)
