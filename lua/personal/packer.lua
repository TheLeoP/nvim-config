local packer = require('packer')
local luarocks = require('packer.luarocks')

luarocks.install_commands()

return packer.startup(function(use, use_rocks)

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
  use 'itchyny/lightline.vim'

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
  use 'mfussenegger/nvim-dap'
  use 'rcarriga/nvim-dap-ui'
  -- lua en neovim debug server
  use 'jbyuki/one-small-step-for-vimkind'

  -- test en vim
  use 'vim-test/vim-test'

  -- lsp
  use 'neovim/nvim-lspconfig'
  use 'ray-x/lsp_signature.nvim'
  use {
    'mfussenegger/nvim-jdtls',
  }

  -- coq
  use {
    'ms-jpq/coq_nvim',
    branch = 'coq'
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
  use 'nvim-telescope/telescope.nvim'
  use {
    'nvim-telescope/telescope-fzf-native.nvim',
    run = vim.g.make_cmd
  }
  -- extensiones telescope
  use 'nvim-telescope/telescope-project.nvim'
  use 'nvim-telescope/telescope-file-browser.nvim'

  -- íconos en nvim
  use 'kyazdani42/nvim-web-devicons'

  -- teesitter
  use {
    'nvim-treesitter/nvim-treesitter',
    run = ':TSUpdate',
  }
  use {
    'nvim-treesitter/nvim-treesitter-textobjects',
  }

  -- gps para statusline usando treesitter
  use 'SmiteshP/nvim-gps'

  -- mejor integración con netrw
  use 'tpope/vim-vinegar'

  -- resalta palabra bajo el cursor
  use 'RRethy/vim-illuminate'

  -- extender la capacidad de i_ctrl-a
  use 'monaqa/dial.nvim'

  -- dashboard
  use 'glepnir/dashboard-nvim'

  -- lsp diagnostics
  use 'nvim-lua/lsp-status.nvim'

  -- GUI para vim.ui.input y vim.ui.select
  use 'stevearc/dressing.nvim'

  -- GUI para vim.notify
  use 'rcarriga/nvim-notify'

  -- use_rocks {
  --   'winapi'
  -- }

end)