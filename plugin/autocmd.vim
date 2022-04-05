augroup LuaHighLight
  au!
  au TextYankPost * silent! lua vim.highlight.on_yank {on_visual=true}
augroup end

augroup Templates
  au!
  au BufNewFile */autoregistro-emociones/*.md 0r $NVIMHOME/templates/template-autoregistro.md
augroup end
