" remap
let mapleader = " "

" cambiar current working directory
nnoremap <leader>cd :cd %:p:h<CR>:pwd<CR>

" remap replace with register
xmap <leader>r <Plug>ReplaceWithRegisterVisual
nmap <leader>r <Plug>ReplaceWithRegisterOperator
nmap <leader>rr <Plug>ReplaceWithRegisterLine

" remap move in quickfix-list
nnoremap <silent> ]c :cnext<cr>zzzv
nnoremap <silent> [c :cprev<cr>zzzv

" remap move in quickfix-list
nnoremap <silent> ]l :lnext<cr>zzzv
nnoremap <silent> [l :lprev<cr>zzzv

" mantener centrado al usar n y N
nnoremap n nzzzv
nnoremap N Nzzzv

" mantener posición en J y gJ usando el marcador z
nnoremap J mzJ`z
nnoremap gJ mzgJ`z

" breakpoints para undo en insert mode
inoremap , ,<c-g>u
inoremap . .<c-g>u
inoremap ! !<c-g>u
inoremap ? ?<c-g>u
inoremap ( (<c-g>u
inoremap ) )<c-g>u
inoremap & &<c-g>u
inoremap \| \|<c-g>u
inoremap : :<c-g>u
inoremap ; ;<c-g>u

" jumplist para j y k
nnoremap <silent><expr> k (v:count > 5 ? "m'" . v:count : "") . 'k'
nnoremap <silent><expr> j (v:count > 5 ? "m'" . v:count : "") . 'j'

" manejo de linas en todos los modos
vnoremap <silent> <a-j> :m '>+1<cr>gv=gv
vnoremap <silent> <a-k> :m '<-2<cr>gv=gv
nnoremap <silent> <a-j> :m .+1<cr>==
nnoremap <silent> <a-k> :m .-2<cr>==
inoremap <silent> <a-j> <esc>:m .+1<cr>==gi
inoremap <silent> <a-k> <esc>:m .-2<cr>==gi

" LSP
nnoremap <silent> gd <cmd>lua vim.lsp.buf.definition()<cr>
nnoremap <silent> gD <cmd>lua vim.lsp.buf.declaration()<cr>
nnoremap <silent> gr <cmd>lua vim.lsp.buf.references()<cr>
nnoremap <silent> gi <cmd>lua vim.lsp.buf.implementation()<cr>
nnoremap <silent> <c-k> <cmd>lua vim.lsp.buf.signature_help()<cr>
nnoremap <silent> K <cmd>lua vim.lsp.buf.hover()<cr>
nnoremap <silent> <leader>rn <cmd>lua vim.lsp.buf.rename()<cr>
nnoremap <silent> <leader>ca <cmd>lua vim.lsp.buf.code_action()<CR>
nnoremap <silent> ]e <cmd>lua vim.diagnostic.goto_next()<cr>
nnoremap <silent> [e <cmd>lua vim.diagnostic.goto_prev()<cr>
nnoremap <silent> <leader>e <cmd>lua vim.diagnostic.open_float()<cr>

" formatear
nnoremap <silent> <leader>fm <cmd>lua vim.lsp.buf.formatting_sync(nil, 1000)<cr>

" telescope
" Find files using Telescope command-line sugar.
nnoremap <leader>ff <cmd>Telescope find_files<cr>
nnoremap <leader>fg <cmd>Telescope git_branches<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>
nnoremap <leader>fc <cmd>Telescope current_buffer_fuzzy_find<cr>
nnoremap <leader>fs <cmd>Telescope live_grep<cr>
nnoremap <leader>fds <cmd>Telescope lsp_document_symbols<cr>
nnoremap <leader>fws <cmd>Telescope lsp_workspace_symbols<cr>
nnoremap <leader>fr <cmd>Telescope resume<cr>

" proyectos
nnoremap <leader>fp <cmd>lua require('telescope').extensions.project.project({})<cr>

" personalizado
nnoremap <silent><leader>fi <cmd>lua require("personal.fn_telescope").search_dotfiles()<cr>
nnoremap <silent><leader>fl <cmd>lua require("personal.fn_telescope").search_trabajos()<cr>
nnoremap <silent><leader>fL <cmd>lua require("personal.fn_telescope").browse_trabajos()<cr>
nnoremap <leader>fF <cmd>lua require("personal.fn_telescope").browse_cd_files()<cr>
nnoremap <leader>fa <cmd>lua require("personal.fn_telescope").search_autoregistro()<cr>
nnoremap <leader>fA <cmd>lua require("personal.fn_telescope").browse_autoregistro()<cr>
nnoremap <leader>fnc <cmd>lua require("personal.fn_telescope").search_nota_ciclo_actual_contenido()<cr>
nnoremap <leader>fnn <cmd>lua require("personal.fn_telescope").search_nota_ciclo_actual_nombre()<cr>

" permitir salir del modo terminal con <c-[>
tnoremap <c-[> <c-\><c-n>

" compilar/comprobar sintaxis
nmap <silent> <F7> :w<cr>:Dispatch<cr>

" correr programa
nmap <silent> <F8> :w<cr>:Dispatch<cr>;

" quick semi
nnoremap <leader>; A;<Esc>

" w and q
nnoremap <silent> <leader>w :w<cr>
nnoremap <silent> <leader>q :q<cr>

" vim-test
nnoremap <silent> <leader>tn :TestNearest<cr>
nnoremap <silent> <leader>tf :TestFile<cr>
nnoremap <silent> <leader>ts :TestSuite<cr>
nnoremap <silent> <leader>tl :TestLast<cr>
nnoremap <silent> <leader>tv :TestVisit<cr>

" DAP
nmap <silent> <leader>dc <cmd>lua require('dap').continue()<cr>
nmap <silent> <leader>ds <cmd>lua require('dap').continue()<cr>
nmap <silent> <leader>dr <cmd>lua require('dap').disconnect({restart = true})<cr>
nmap <silent> <leader>de <cmd>lua require('dap').disconnect()<cr><cmd>lua require('dap').close()<cr><cmd>lua require('dapui').close()<cr>
nmap <silent> <leader>dp <cmd>lua require('dap').pause()<cr>
nmap <silent> <leader>db <cmd>lua require('dap').toggle_breakpoint()<cr>
nmap <silent> <leader>dB <cmd>lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<cr>
nmap <silent> <leader>dv <cmd>lua require('dap').step_over()<cr>
nmap <silent> <leader>dsi <cmd>lua require('dap').step_into()<cr>
nmap <silent> <leader>dso <cmd>lua require('dap').step_out()<cr>
nmap <silent> <leader>dsb <cmd>lua require('dap').step_back()<cr>
nmap <silent> <leader>dtc <cmd>lua require('dap').run_to_cursor()<cr>

" vim-fugitive
nnoremap <silent> <leader>g :G<cr>

" ejecutar archivos
function! s:executor() abort
    if &filetype == 'lua'
        execute(printf(":lua %s", getline(".")))
    elseif &filetype == 'vim'
        exe getline(".")
    endif
endfunction

function! s:save_and_exec() abort
    if &filetype == 'vim'
        :silent! write
        :source %
    elseif &filetype == 'lua'
        :silent! write
        :luafile %
    endif
endfunction

nnoremap <leader>x :call <SID>executor()<cr>
nnoremap <leader><leader>x :call <SID>save_and_exec()<cr>

inoremap <silent><expr> <BS>    pumvisible() ? "\<C-e><BS>"  : "\<BS>"
inoremap <silent><expr> <CR>    pumvisible() ? (complete_info().selected == -1 ? "\<C-e><CR>" : "\<C-y>") : "\<CR>"
inoremap <silent><expr> <Tab>   pumvisible() ? "\<down>" : "\<Tab>"
inoremap <silent><expr> <S-Tab> pumvisible() ? "\<up>" : "\<BS>"

" aumentar capacidad de ctrl-a
nmap <c-a> <Plug>(dial-increment)
nmap <c-x> <Plug>(dial-decrement)
vmap <c-a> <Plug>(dial-increment)
vmap <c-x> <Plug>(dial-decrement)
vmap g<c-a> <Plug>(dial-increment-additional)
vmap g<c-x> <Plug>(dial-decrement-additional)

" permite ejecutar un comando seleccionado visualmente en la última consola
" abierta
vnoremap <silent> <leader><leader>e <cmd>lua require('personal.fn_util').visual_ejecutar_en_terminal()<cr>

" grabar y cargar sesiones con un nombre
nnoremap <leader><leader>ss <cmd>lua require('personal.fn_dashboard').guardar_sesion()<cr>
nnoremap <leader><leader>sl <cmd>lua require('personal.fn_dashboard').cargar_sesion()<cr>

" crear un nuevo autoregistro personal
nnoremap <leader>na <cmd>lua require('personal.fn_util').nuevo_autoregistro()<cr>
nnoremap <leader>nn <cmd>lua require('personal.fn_util').nueva_nota_U()<cr>

" mapping para cambiar ys por <leader>s
nmap <leader>s  <Plug>Ysurround
nmap <leader>S  <Plug>YSurround
nmap <leader>ss <Plug>Yssurround
nmap <leader>Ss <Plug>YSsurround
nmap <leader>SS <Plug>YSsurround
