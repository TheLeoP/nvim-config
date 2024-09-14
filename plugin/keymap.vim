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
nnoremap <silent> [Q <cmd>cfirst<cr>zzzv
nnoremap <silent> [q <cmd>cprev<cr>zzzv
nnoremap <silent> ]q <cmd>cnext<cr>zzzv
nnoremap <silent> ]Q <cmd>clast<cr>zzzv

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

nnoremap <silent> ]e <cmd>lua vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })<cr>
nnoremap <silent> [e <cmd>lua vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })<cr>
nnoremap <silent> <leader>e <cmd>lua vim.diagnostic.open_float()<cr>
" [d and ]d are now default mappings for navigating diagnostics

" permitir salir del modo terminal con <c-[>
tnoremap  <c-\><c-n>

" w and q
nnoremap <silent> <leader>w <cmd>w<cr>
nnoremap <silent> <leader>q <cmd>q<cr>

" permite ejecutar un comando seleccionado visualmente en la última consola
" abierta
xnoremap <silent> <leader><leader>e :lua require('personal.util.general').visual_ejecutar_en_terminal()<cr>

" borrar palabra con <c-bs>
imap <C-BS> 
imap  

" mejores macros
nnoremap <silent> @ <cmd>execute "noautocmd normal! " . v:count1 . "@" . getcharstr()<cr>
xnoremap <silent> @ :<C-U>execute "noautocmd '<,'>normal! " . v:count1 . "@" . getcharstr()<cr>

" tabs
nnoremap <a-h> <cmd>tabprevious<cr>
nnoremap <a-l> <cmd>tabnext<cr>

inoremap <c-a> <c-k>
