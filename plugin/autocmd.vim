augroup LuaHighLight
  au!
  au TextYankPost * silent! lua vim.highlight.on_yank {on_visual=true}
augroup end

augroup LSPJava
  au!
  au FileType java lua require('personal.lsp').jdtls_setup()
augroup end

augroup Templates
  au!
  au BufNewFile {\d,\d\d}-{\d,\d\d}-{\d\d\d\d}\ {\d,\d\d}-{\d,\d\d}-{\d,\d\d}.md 0r $NVIMHOME/templates/template-autoregistro.md
" 7-9-2021 22-15-30.md
augroup end
