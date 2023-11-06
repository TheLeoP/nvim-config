setlocal spell
setlocal wrap
setlocal colorcolumn=0

let b:undo_ftplugin = "setlocal nospell nowrap"

nnoremap <expr><buffer> j v:count ? 'j' : 'gj'
nnoremap <expr><buffer> k v:count ? 'k' : 'gk'
nnoremap <buffer> gj j
nnoremap <buffer> gk k

vmap <buffer> <leader>b S*gvS*
vmap <buffer> <leader>i S*
