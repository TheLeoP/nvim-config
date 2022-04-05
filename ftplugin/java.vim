" remap

" busca el reporte por defecto de pruebas de gradle y lo abre en chrome
nnoremap <silent><buffer> <leader>pr :exe '!start chrome '.getcwd().'\build\reports\tests\test\index.html'<cr>

nnoremap <silent><buffer> <F9> v<cmd>terminal gradle run<cr>

" configuración plugins
" dispatch
let b:dispatch = 'gradle compileJava'

nnoremap <silent><buffer> <leader>cev <Cmd>lua require('jdtls').extract_variable()<CR>
vnoremap <silent><buffer> <leader>cev <Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>
nnoremap <silent><buffer> <leader>cec <Cmd>lua require('jdtls').extract_constant()<CR>
vnoremap <silent><buffer> <leader>cec <Esc><Cmd>lua require('jdtls').extract_constant(true)<CR>
vnoremap <silent><buffer> <leader>cem <Esc><Cmd>lua require('jdtls').extract_method(true)<CR>

lua require('personal.lsp').jdtls_setup()
