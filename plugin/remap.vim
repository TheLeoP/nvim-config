" cambiar current working directory
nnoremap <leader>cd <cmd>tcd %:p:h<CR>

" remap replace with register
xmap <leader>r <Plug>ReplaceWithRegisterVisual
nmap <leader>r <Plug>ReplaceWithRegisterOperator
nmap <leader>rr <Plug>ReplaceWithRegisterLine

nmap <nowait> { [
nmap <nowait> } ]
xmap <nowait> { [
xmap <nowait> } ]

nnoremap <nowait> [ {
nnoremap <nowait> ] }
xnoremap <nowait> [ {
xnoremap <nowait> ] }


" remap move in quickfix-list
nnoremap <silent> ]q :cnext<cr>zzzv
nnoremap <silent> [q :cprev<cr>zzzv

" remap move in quickfix-list
nnoremap <silent> ]l :lnext<cr>zzzv
nnoremap <silent> [l :lprev<cr>zzzv

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
xnoremap <silent> <a-j> :m '>+1<cr>gv=gv
xnoremap <silent> <a-k> :m '<-2<cr>gv=gv
nnoremap <silent> <a-j> :m .+1<cr>==
nnoremap <silent> <a-k> :m .-2<cr>==
inoremap <silent> <a-j> <esc>:m .+1<cr>==gi
inoremap <silent> <a-k> <esc>:m .-2<cr>==gi

vnoremap <silent> <a-h> <cmd>noautocmd normal! xhhp`<h<c-v>`>h<cr>
vnoremap <silent> <a-l> <cmd>noautocmd normal! xp`<l<c-v>`>l<cr>

nnoremap <silent> ]e <cmd>lua vim.diagnostic.goto_next()<cr>
nnoremap <silent> [e <cmd>lua vim.diagnostic.goto_prev()<cr>

" telescope
" Find files using Telescope command-line sugar.
nnoremap <leader>ff <cmd>Telescope find_files hidden=true<cr>
nnoremap <leader>fg <cmd>Telescope git_branches<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>
nnoremap <leader>fc <cmd>Telescope current_buffer_fuzzy_find<cr>
nnoremap <leader>fs <cmd>Telescope live_grep_args<cr>
nnoremap <leader>fr <cmd>Telescope resume<cr>
nnoremap <leader>fwd <cmd>Telescope diagnostics<cr>

" proyectos
nnoremap <leader>fp <cmd>Telescope projects<cr>

" personalizado
nnoremap <leader>fi <cmd>lua require("personal.util.telescope").search_nvim_config()<cr>
nnoremap <leader>fl <cmd>lua require("personal.util.telescope").search_trabajos()<cr>
nnoremap <leader>fL <cmd>lua require("personal.util.telescope").browse_trabajos()<cr>
nnoremap <leader>fF <cmd>Telescope file_browser<cr>
nnoremap <leader>fnc <cmd>lua require("personal.util.telescope").search_nota_ciclo_actual_contenido()<cr>
nnoremap <leader>fnn <cmd>lua require("personal.util.telescope").search_nota_ciclo_actual_nombre()<cr>

nnoremap <leader>fan <cmd>lua require("personal.util.telescope").search_autoregistro_nombre()<cr>
nnoremap <leader>fac <cmd>lua require("personal.util.telescope").search_autoregistro_contenido()<cr>

" permitir salir del modo terminal con <c-[>
tnoremap  <c-\><c-n>
tnoremap <c-{><c-{> <c-\><c-n>

" w and q
nnoremap <silent> <leader>w :w<cr>
nnoremap <silent> <leader>q :q<cr>

" vim-test
nnoremap <silent> <leader>pn :TestNearest<cr>
nnoremap <silent> <leader>pf :TestFile<cr>
nnoremap <silent> <leader>ps :TestSuite<cr>
nnoremap <silent> <leader>pl :TestLast<cr>
nnoremap <silent> <leader>pv :TestVisit<cr>

" DAP
nmap <silent> <leader>dc <cmd>lua require('dap').continue()<cr>
nmap <silent> <leader>ds <cmd>lua require('dap').continue()<cr>
nmap <silent> <leader>dr <cmd>lua require('dap').disconnect({restart = true})<cr>
nmap <silent> <leader>de <cmd>lua require('dap').terminate()<cr>
nmap <silent> <leader>dp <cmd>lua require('dap').pause()<cr>
nmap <silent> <leader>db <cmd>lua require('dap').toggle_breakpoint()<cr>
nmap <silent> <leader>dB <cmd>lua require'dap'.set_breakpoint(vim.fn.input('Breakpoint condition: '))<cr>
nmap <silent> <leader>dv <cmd>lua require('dap').step_over()<cr>
nmap <silent> <leader>dsi <cmd>lua require('dap').step_into()<cr>
nmap <silent> <leader>dso <cmd>lua require('dap').step_out()<cr>
nmap <silent> <leader>dsb <cmd>lua require('dap').step_back()<cr>
nmap <silent> <leader>dtc <cmd>lua require('dap').run_to_cursor()<cr>

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
vmap g<c-a> g<Plug>(dial-increment)
vmap g<c-x> g<Plug>(dial-decrement)

" permite ejecutar un comando seleccionado visualmente en la última consola
" abierta
vnoremap <silent> <leader><leader>e <cmd>lua require('personal.util.general').visual_ejecutar_en_terminal()<cr>

" grabar y cargar sesiones con un nombre
nnoremap <leader><leader>ss <cmd>lua require('personal.util.dashboard').guardar_sesion()<cr>
nnoremap <leader><leader>sl <cmd>Telescope possession list<cr>

nnoremap <leader>nn <cmd>lua require('personal.util.general').nueva_nota_U()<cr>
nnoremap <leader>na <cmd>lua require('personal.util.general').nuevo_autoregistro()<cr>

" mapping para cambiar ys por <leader>s
nmap <leader>s  <Plug>Ysurround
nmap <leader>S  <Plug>YSurround
nmap <leader>ss <Plug>Yssurround
nmap <leader>Ss <Plug>YSsurround
nmap <leader>SS <Plug>YSsurround

" borar palabra con <c-bs> o <c-h>
inoremap <C-BS> 
inoremap  

" mejores macros
nnoremap @ <cmd>execute "noautocmd normal! " . v:count1 . "@" . getcharstr()<cr>
xnoremap @ :<C-U>execute "noautocmd '<,'>norm! " . v:count1 . "@" . getcharstr()<cr>

" mejor <c-l>
nnoremap <c-l> <cmd>nohlsearch<bar>diffupdate<bar>lua require('notify').dismiss()<cr><cmd>normal! <c-l><cr>

" tabs
nnoremap <a-h> <cmd>tabprevious<cr>
nnoremap <a-l> <cmd>tabnext<cr>

" Dispatch
nnoremap ¿<cr> <cmd>Dispatch<cr>
nnoremap ¿<space> :Dispatch<space>
nnoremap ¿! <cmd>Dispatch!
nnoremap ¿? <cmd>FocusDispatch<cr>

" refactoring
xnoremap <leader><leader>re <esc><cmd>lua require('refactoring').refactor('Extract Function')<cr>
xnoremap <leader><leader>rf <esc><cmd>lua require('refactoring').refactor('Extract Function To File')<cr>
xnoremap <leader><leader>rv <esc><cmd>lua require('refactoring').refactor('Extract Variable')<cr>
xnoremap <leader><leader>ri <esc><cmd>lua require('refactoring').refactor('Inline Variable')<cr>
nnoremap <leader><leader>rbb <cmd>lua require('refactoring').refactor('Extract Block')<cr>
nnoremap <leader><leader>rbf <cmd>lua require('refactoring').refactor('Extract Block To File')<cr>
nnoremap <leader><leader>ri <esc><cmd>lua require('refactoring').refactor('Inline Variable')<cr>

nnoremap <leader><leader>rpP <cmd>lua require('refactoring').debug.printf({below = false})<cr>
nnoremap <leader><leader>rpp <cmd>lua require('refactoring').debug.printf({below = true})<cr>
nnoremap <leader><leader>rpv <cmd>lua require('refactoring').debug.print_var({below = true, normal = true})<cr>
xnoremap <leader><leader>rpv <esc><cmd>lua require('refactoring').debug.print_var({below = true})<cr>
nnoremap <leader><leader>rc <cmd>lua require('refactoring').debug.cleanup({})<cr>

" fern
nnoremap - <cmd>Fern . -reveal=%<cr>
