" remap

" busca el reporte por defecto de pruebas de gradle y lo abre en chrome
nnoremap <silent><buffer> <leader>pr :exe '!start chrome '.getcwd().'\build\reports\tests\test\index.html'<cr>

nnoremap <silent><buffer> <F9> <cmd>wa<cr>s<cmd>terminal gradle run<cr>

" configuración plugins
" dispatch
let b:dispatch = 'gradle compileJava'
compiler gradle

lua require('personal.lsp').jdtls_setup()
