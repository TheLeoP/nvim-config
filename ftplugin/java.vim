" remap

" busca el reporte por defecto de pruebas de gradle y lo abre en chrome
nnoremap <silent><buffer> <leader>tr :exe '!start chrome '.getcwd().'\build\reports\tests\test\index.html'<cr>

nnoremap <silent><buffer> <F9> v<cmd>terminal gradle run<cr>

" configuración plugins
" dispatch
let b:dispatch = 'gradle compileJava'

nnoremap <silent><buffer> <leader>ca <Cmd>lua require('jdtls').code_action()<CR>
vnoremap <silent><buffer> <leader>ca <Esc><Cmd>lua require('jdtls').code_action(true)<CR>
nnoremap <silent><buffer> <leader>rf <Cmd>lua require('jdtls').code_action(false, 'refactor')<CR>

nnoremap <silent><buffer> <leader>ev <Cmd>lua require('jdtls').extract_variable()<CR>
vnoremap <silent><buffer> <leader>ev <Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>
nnoremap <silent><buffer> <leader>ec <Cmd>lua require('jdtls').extract_constant()<CR>
vnoremap <silent><buffer> <leader>ec <Esc><Cmd>lua require('jdtls').extract_constant(true)<CR>
vnoremap <silent><buffer> <leader>em <Esc><Cmd>lua require('jdtls').extract_method(true)<CR>
