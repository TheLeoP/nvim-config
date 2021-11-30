setlocal spell
setlocal spelllang=es,en
setlocal wrap
setlocal colorcolumn=0

nmap <buffer> <leader>sc z=
nmap <buffer> <leader>sg zg
nmap <buffer> <leader>sug zug
nmap <buffer> <leader>sw zw
nmap <buffer> <leader>suw zuw

nnoremap <buffer> j gj
nnoremap <buffer> k gk
nnoremap <buffer> gj j
nnoremap <buffer> gk k

vmap <buffer> <leader>b S*gvS*
vmap <buffer> <leader>i S*
