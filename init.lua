-- impatient.nvim
require('impatient')

-- funciones y variable globales peronales
require('personal.globals')

require('personal.install')

-- vim polyglot
require('personal.polyglot')


-- plugin
require('personal.packer')

-- lua/colorscheme
require('personal.colorscheme')

-- lua/coq
require('personal.coq')

-- lua/lsp
require('personal.lsp')
require('personal.signature')

-- lua/devicons
require('personal.devicons')

-- lua/telescope
require('personal.telescope')

-- lua/treesitter
require('personal.treesitter')
require('personal.treesitter-textsubjects')

-- lua dap
require('personal.dap')

-- lua dapui
require('personal.dapui')

-- lua gps
require('personal.nvim-gps')

-- lua dashboard
require('personal.dashboard')

-- lua lightline
require('personal.lightline')

-- lua dressing
require('personal.dressing')

-- lua notify
require('personal.notify')

-- lua venn
require('personal.venn')

-- lua rest support
require('personal.rest')

-- lua trouble
require('personal.trouble')

-- lua colorizer
require('personal.colorizer')

-- lua instant
require('personal.instant')

-- tags
require('personal.gutentags')

-- ayuda indent
require('personal.blankline')

-- símbolos en signcolumn para git
require('personal.gitsigns')

-- neovide config
require('personal.neovide')

-- emmet
require('personal.emmet')

-- test
require('personal.vim-test')

require('personal.suda')
