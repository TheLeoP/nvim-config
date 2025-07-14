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
inoremap [ [<c-g>u
inoremap ] ]<c-g>u
inoremap { {<c-g>u
inoremap } }<c-g>u
inoremap & &<c-g>u
inoremap \| \|<c-g>u
inoremap : :<c-g>u
inoremap ; ;<c-g>u
inoremap = =<c-g>u
inoremap < <<c-g>u
inoremap > ><c-g>u

" easier on hands
nnoremap <silent> <leader>w <cmd>w<cr>
nnoremap <silent> <leader>q <cmd>q<cr>
noremap <c-c> <esc>

" permite ejecutar un comando seleccionado visualmente en la última consola
" abierta
xnoremap <silent> <leader><leader>e :lua require('personal.util.general').visual_ejecutar_en_terminal()<cr>

" borrar palabra con <c-bs>
imap <C-BS> 
imap  

" mejores macros
nnoremap <silent> @ <cmd>execute "noautocmd normal! " . v:count1 . "@" . getcharstr()<cr>
xnoremap <silent> @ :<C-U>execute "noautocmd '<,'>normal! " . v:count1 . "@" . getcharstr()<cr>

nnoremap <c-w>n <cmd>vertical new<cr>
nnoremap <c-w><c-n> <cmd>vertical new<cr>
