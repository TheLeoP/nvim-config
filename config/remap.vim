" remap
let mapleader = " "

" cambiar current working directory
nnoremap <leader>cd :cd %:p:h<CR>:pwd<CR>

" remap replace with register
xmap <leader>r <Plug>ReplaceWithRegisterVisual
nmap <leader>r <Plug>ReplaceWithRegisterOperator
nmap <leader>rr <Plug>ReplaceWithRegisterLine

" remap move in quickfix-list
nnoremap <silent> ]l :cnext<cr>zzzv
nnoremap <silent> [l :cprev<cr>zzzv

" Y más intuitiva
nnoremap Y y$

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
nnoremap <expr> k (v:count > 5 ? "m'" . v:count : "") . 'k'
nnoremap <expr> j (v:count > 5 ? "m'" . v:count : "") . 'j'

" manejo de linas en todos los modos
vnoremap J :m '>+1<cr>gv=gv
vnoremap K :m '<-2<cr>gv=gv
nnoremap <leader>j :m .+1<cr>==
nnoremap <leader>k :m .-2<cr>==
inoremap <a-j> <esc>:m .+1<cr>==gi
inoremap <a-k> <esc>:m .-2<cr>==gi

" LSP
nnoremap <silent> gd <cmd>lua vim.lsp.buf.definition()<cr>
nnoremap <silent> gD <cmd>lua vim.lsp.buf.declaration()<cr>
nnoremap <silent> gr <cmd>lua vim.lsp.buf.references()<cr>
nnoremap <silent> gi <cmd>lua vim.lsp.buf.implementation()<cr>
nnoremap <silent> <c-k> <cmd>lua vim.lsp.buf.signature_help()<cr>
nnoremap <silent> K <cmd>lua vim.lsp.buf.hover()<cr>
nnoremap <silent> <leader>rn <cmd>lua vim.lsp.buf.rename()<cr>
nnoremap <silent> <leader>ca <cmd>lua vim.lsp.buf.code_action()<CR>
nnoremap <silent> ]e <cmd>lua vim.lsp.diagnostic.goto_next()<cr>
nnoremap <silent> [e <cmd>lua vim.lsp.diagnostic.goto_prev()<cr>

" formatear
nnoremap <silent> <leader>fm <cmd>lua vim.lsp.buf.formatting_sync(nil, 1000)<cr>

" teclas
inoremap <silent><expr> <C-Space> compe#complete()
inoremap <silent><expr> <CR> compe#confirm('<CR>')
inoremap <silent><expr> <C-e> compe#close('<C-e>')
inoremap <silent><expr> <C-f> compe#scroll({ 'delta': +4 })
inoremap <silent><expr> <C-d> compe#scroll({ 'delta': -4 })

" telescope
" Find files using Telescope command-line sugar.
nnoremap <leader>ff <cmd>lua require("personal.telescope").search_cd_files()<cr>
nnoremap <leader>fg <cmd>Telescope git_branches<cr>
nnoremap <leader>fb <cmd>Telescope buffers<cr>
nnoremap <leader>fh <cmd>Telescope help_tags<cr>
nnoremap <leader>fj <cmd>Telescope current_buffer_fuzzy_find<cr>
nnoremap <leader>fds <cmd>Telescope lsp_document_symbols<cr>

" personalizado
nnoremap <silent><leader>fi <cmd>lua require("personal.telescope").search_dotfiles()<cr>
nnoremap <silent><leader>fl <cmd>lua require("personal.telescope").search_trabajos()<cr>
nnoremap <silent><leader>fL <cmd>lua require("personal.telescope").browse_trabajos()<cr>
nnoremap <leader>fF <cmd>lua require("personal.telescope").browse_cd_files()<cr>

" permitir salir del modo terminal con <c-[>
tnoremap <c-[> <c-\><c-n>

" borrar una palabra en modo insert con <c-BS>
inoremap <c-bs> <c-G>u<c-w>

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

" vimspector
" vimspector debug inspect
nmap <silent> <leader>di <Plug>VimspectorBallonEval

" vimspector debug continue
nmap <silent> <leader>dc <Plug>VimspectorContinue

" vimspector debug start
nmap <silent> <leader>ds <Plug>VimspectorContinue

" vimspector debug stop
nmap <silent> <leader>dx <Plug>VimspectorStop

" vimspector debug restart
nmap <silent> <leader>dr <Plug>VimspectorRestart

" vimspector debug restart
nmap <silent> <leader>de :VimspectorReset<cr>

" vimspector debug pause
nmap <silent> <leader>dp <Plug>VimspectorPause

" vimspector debug toggle breakpoint
nmap <silent> <leader>db <Plug>VimspectorToggleBreakpoint

" vimspector debug toggle conditional breakpoint
nmap <silent> <leader>dB <Plug>VimspectorToggleConditionalBreakpoint

" vimspector debug add function breakpoint
nmap <silent> <leader>dfb <Plug>VimspectorAddFunctionBreakpoint

" vimspector debug step over
nmap <silent> <leader>dv <Plug>VimspectorStepOver

" vimspector debug step into
nmap <silent> <leader>dsi <Plug>VimspectorStepInto

" vimspector debug step out
nmap <silent> <leader>dso <Plug>VimspectorStepOut

" vimspector debug run to cursor
nmap <silent> <leader>dtc <Plug>VimspectorRunToCursor

" vim-fugitive
nnoremap <silent> <leader>g :G<cr>

" alt + hjkl para cambiar tamaño de ventanas
nnoremap <M-j> :resize +2<cr>
nnoremap <M-k> :resize -2<cr>
nnoremap <M-h> :vertical resize -2<cr>
nnoremap <M-l> :vertical resize +2<cr>

" funciones

" lua
function! s:executor() abort
    if &filetype == 'lua'
        execute(printf(":lua %s", getline(".")))
    elseif &filetype == 'vim'
        exe getline(">")
    endif
endfunction

nnoremap <leader>x :call <SID>executor()<cr>

function! s:save_and_exec() abort
    if &filetype == 'vim'
        :silent! write
        :source %
    elseif &filetype == 'lua'
        :silent! write
        :luafile %
    endif
endfunction

nnoremap <leader><leader>x :call <SID>save_and_exec()<cr>
