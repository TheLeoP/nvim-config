" remap
nnoremap <buffer><F8> <cmd>w<cr><cmd>vs<cr><c-w>l<cmd>exe 'term lua "'.expand("%:p").'"'<cr>
