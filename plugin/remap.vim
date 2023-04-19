" cambiar current working directory
nnoremap <leader>cd <cmd>tcd %:p:h<CR>

nmap <nowait> { [
nmap <nowait> } ]
xmap <nowait> { [
xmap <nowait> } ]

nnoremap <M-{> {
nnoremap <M-}> }
xnoremap <M-{> {
xnoremap <M-}> }


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
nnoremap <silent><expr> k (v:count > 0 ? "m'" . v:count : "") . 'k'
nnoremap <silent><expr> j (v:count > 0 ? "m'" . v:count : "") . 'j'

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

" permitir salir del modo terminal con <c-[>
tnoremap  <c-\><c-n>
tnoremap <c-{><c-{> <c-\><c-n>

" w and q
nnoremap <silent> <leader>w :w<cr>
nnoremap <silent> <leader>q :q<cr>

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

nnoremap <silent><leader>x :call <SID>executor()<cr>
nnoremap <silent><leader><leader>x :call <SID>save_and_exec()<cr>

" permite ejecutar un comando seleccionado visualmente en la última consola
" abierta
vnoremap <silent> <leader><leader>e <cmd>lua require('personal.util.general').visual_ejecutar_en_terminal()<cr>

nnoremap <leader>nn <cmd>lua require('personal.util.general').nueva_nota_U()<cr>
nnoremap <leader>na <cmd>lua require('personal.util.general').nuevo_autoregistro()<cr>

" borar palabra con <c-bs> o <c-h>
inoremap <C-BS> 
inoremap  

" mejores macros
nnoremap @ <cmd>execute "noautocmd normal! " . v:count1 . "@" . getcharstr()<cr>
xnoremap @ :<C-U>execute "noautocmd '<,'>norm! " . v:count1 . "@" . getcharstr()<cr>

" tabs
nnoremap <a-h> <cmd>tabprevious<cr>
nnoremap <a-l> <cmd>tabnext<cr>
