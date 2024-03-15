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
inoremap = =<c-g>u

nnoremap <silent> ]e <cmd>lua vim.diagnostic.goto_next({ severity = vim.diagnostic.severity.ERROR })<cr>
nnoremap <silent> [e <cmd>lua vim.diagnostic.goto_prev({ severity = vim.diagnostic.severity.ERROR })<cr>
nnoremap <silent> <leader>e <cmd>lua vim.diagnostic.open_float()<cr>
nnoremap <silent> ]d <cmd>lua vim.diagnostic.goto_next()<cr>
nnoremap <silent> [d <cmd>lua vim.diagnostic.goto_prev()<cr>

" permitir salir del modo terminal con <c-[>
tnoremap  <c-\><c-n>
tnoremap <c-{><c-{> <c-\><c-n>

" w and q
nnoremap <silent> <leader>w <cmd>w<cr>
nnoremap <silent> <leader>q <cmd>q<cr>

" permite ejecutar un comando seleccionado visualmente en la última consola
" abierta
xnoremap <silent> <leader><leader>e :lua require('personal.util.general').visual_ejecutar_en_terminal()<cr>

" borrar palabra con <c-bs>
inoremap <C-BS> 
inoremap  

" mejores macros
nnoremap @ <cmd>execute "noautocmd normal! " . v:count1 . "@" . getcharstr()<cr>
xnoremap @ :<C-U>execute "noautocmd '<,'>normal! " . v:count1 . "@" . getcharstr()<cr>

" tabs
nnoremap <a-h> <cmd>tabprevious<cr>
nnoremap <a-l> <cmd>tabnext<cr>

inoremap <c-a> <c-k>
