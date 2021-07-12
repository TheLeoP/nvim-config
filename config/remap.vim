" remap
let mapleader = " "

" cambiar current working directory
nnoremap <leader>cd :cd %:p:h<CR>:pwd<CR>

" remap replace with register
xmap <leader>r <Plug>ReplaceWithRegisterVisual
nmap <leader>r <Plug>ReplaceWithRegisterOperator
nmap <leader>rr <Plug>ReplaceWithRegisterLine

" remap move in quickfix-list
nnoremap <silent> ]l :cnext<cr>
nnoremap <silent> [l :cprev<cr>

" LSP
nnoremap <silent> gd <cmd>lua vim.lsp.buf.definition()<CR>
nnoremap <silent> gD <cmd>lua vim.lsp.buf.declaration()<CR>
nnoremap <silent> gr <cmd>lua vim.lsp.buf.references()<CR>
nnoremap <silent> gi <cmd>lua vim.lsp.buf.implementation()<CR>
nnoremap <silent> <c-k> <cmd>lua require('lspsaga.hover').render_hover_doc()<CR>
nnoremap <silent> <leader>rn <cmd>lua require('lspsaga.rename').rename()<CR>
nnoremap <silent> <leader>ca <cmd>lua require('lspsaga.codeaction').code_action()<CR>
nnoremap <silent> <leader>k <cmd>lua require('lspsaga.signaturehelp').signature_help()<CR>
nnoremap <silent> ]e <cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_next()<CR>
nnoremap <silent> [e <cmd>lua require'lspsaga.diagnostic'.lsp_jump_diagnostic_prev()<CR>

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
