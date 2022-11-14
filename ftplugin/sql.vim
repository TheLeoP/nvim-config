" remap
nnoremap <buffer> <F8> <cmd>DBUIToggle<cr>
nnoremap <buffer><silent><expr> <F9> b:db == '' ? "<cmd>let b:url = input('Ingrese la url: ')" : "<cmd>%DB b:url<cr>"
