" set
source $NVIMHOME/config/set.vim

" plugin
luafile $NVIMHOME/lua/plugin.lua

" remap
source $NVIMHOME/config/remap.vim

" lua/remap
source $NVIMHOME/lua/remap.lua

" highlight
source $NVIMHOME/config/highlight.vim

" lua/colorscheme
source $NVIMHOME/lua/colorscheme.lua

" lua/config
luafile $NVIMHOME/lua/personal/config.lua

" lua/telescope
luafile $NVIMHOME/lua/personal/telescope.lua

" lua/treesitter
luafile $NVIMHOME/lua/personal/treesitter.lua

" lua dap
luafile $NVIMHOME/lua/personal/dap.lua

" lua dapui
luafile $NVIMHOME/lua/personal/dapui.lua

augroup LuaHighLight
  au!
  au TextYankPost * silent! lua vim.highlight.on_yank {on_visual=true}
augroup end

augroup LSPJava
  au!
  au FileType java lua require('personal.config').jdtls_setup()
augroup end
