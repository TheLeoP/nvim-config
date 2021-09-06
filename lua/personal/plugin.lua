return require('packer').startup(function(use)

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
  use {
    'ms-jpq/coq_nvim',
    branch = 'coq'
  }
  use {
    'ms-jpq/coq.artifacts',
    branch = 'artifacts'
  }
  use 'ray-x/lsp_signature.nvim'
  use 'mfussenegger/nvim-jdtls'

  -- telescope
  use 'nvim-lua/popup.nvim'
  use 'nvim-lua/plenary.nvim'
  use 'nvim-telescope/telescope.nvim'
  use {
    'nvim-telescope/telescope-fzf-native.nvim',
    run = vim.g.make_cmd
  }

  -- extension para projectos en telescope
  use 'nvim-telescope/telescope-project.nvim'

  -- íconos en nvim
  use 'kyazdani42/nvim-web-devicons'

  -- teesitter
  use {
    'nvim-treesitter/nvim-treesitter',
    branch = '0.5-compat',
    run = ':TSUpdate',
  }
  use {
    'nvim-treesitter/nvim-treesitter-textobjects',
    branch = '0.5-compat'
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

end)
