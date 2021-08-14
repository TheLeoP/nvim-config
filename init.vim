" set
source $NVIMHOME/viml/set.vim

" plugin
luafile $NVIMHOME/lua/plugin.lua

" remap
source $NVIMHOME/viml/remap.vim

" highlight
source $NVIMHOME/viml/highlight.vim

" lua/colorscheme
source $NVIMHOME/lua/colorscheme.lua

" lua/compe
luafile $NVIMHOME/lua/personal/compe.lua

" lua/lsp
luafile $NVIMHOME/lua/personal/lsp.lua

" lua/devicons
luafile $NVIMHOME/lua/personal/devicons.lua

" lua/telescope
luafile $NVIMHOME/lua/personal/telescope.lua

" lua/treesitter
luafile $NVIMHOME/lua/personal/treesitter.lua

" lua dap
luafile $NVIMHOME/lua/personal/dap.lua

" lua dapui
luafile $NVIMHOME/lua/personal/dapui.lua

" autocmd
source $NVIMHOME/viml/autocmd.vim
