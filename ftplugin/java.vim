" remap
" inicia el debugger del programa de gradle y permite que vimspector haga
" attach a él
nnoremap <silent><buffer> <leader>ds :lua require('personal.fn_dap').iniciar_debug_java()<cr>

" TODO: hacer un remap para dr que funcione

" busca el reporte por defecto de pruebas de gradle y lo abre en chrome
nnoremap <silent><buffer> <leader>tr :exe '!start chrome '.getcwd().'\build\reports\tests\test\index.html'<cr>

" configuración plugins
" dispatch
let b:dispatch = 'gradle compileJava'

lua print('algo')
lua require('personal.config').jdtls_setup()

nnoremap <silent><buffer> <leader>ca <Cmd>lua require('jdtls').code_action()<CR>
vnoremap <silent><buffer> <leader>ca <Esc><Cmd>lua require('jdtls').code_action(true)<CR>
nnoremap <silent><buffer> <leader>rf <Cmd>lua require('jdtls').code_action(false, 'refactor')<CR>

nnoremap <silent><buffer> ev <Cmd>lua require('jdtls').extract_variable()<CR>
vnoremap <silent><buffer> ev <Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>
nnoremap <silent><buffer> ec <Cmd>lua require('jdtls').extract_constant()<CR>
vnoremap <silent><buffer> ec <Esc><Cmd>lua require('jdtls').extract_constant(true)<CR>
vnoremap <silent><buffer> em <Esc><Cmd>lua require('jdtls').extract_method(true)<CR>
