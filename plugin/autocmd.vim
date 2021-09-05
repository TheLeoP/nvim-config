augroup LuaHighLight
  au!
  au TextYankPost * silent! lua vim.highlight.on_yank {on_visual=true}
augroup end

augroup LSPJava
  au!
  au FileType java lua require('personal.lsp').jdtls_setup()
augroup end
