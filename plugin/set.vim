set number  "muestra los números de las lineas en el lado izquierdo
set relativenumber  "muestra los números relativos a la izquierda
set nowrap  "las líneas largas se muestran como una sola línea

set spelllang=es,en

set noswapfile  "configura vim para no crear archivos .swap
set nobackup    "configura vim para no crear archivos de respaldo
set nowritebackup
set undofile    "configura vim para sí crear archivos de deshacer/rehacer
set clipboard=unnamedplus   "permite que todo lo copiado vaya también al clipboard del sistema

set conceallevel=0

set hlsearch
set ignorecase  "case insensitive cuando se busca en minúsculas
set smartcase   "case sensitive cuando se busca en mayúsculas

set smarttab
set expandtab
set shiftwidth=4

set scrolloff=8
set cmdheight=2 "número de líneas para la consola

set noshowmode  "no muestra el modo de vim (actualmente tengo un plug-in instalado que muestra esa y otra información)
set signcolumn=yes

set updatetime=300

if has('win32')
    set undodir=~/undodir    "señala el directorio en el cual guardar los archivos de deshacer/rehacer
endif
let &guifont = 'CaskaydiaCove Nerd Font Mono:h12'

if executable('rg')
    set grepprg=rg\ --vimgrep\ --hidden
    set grepformat=%f:%l:%c:%m
endif

" mouse
set mouse=a

" split
set splitbelow
set splitright

set laststatus=3

set cursorline

set diffopt+=vertical,context:99

set shortmess+=w
set shortmess+=s

" Disable health checks for these providers.
let g:loaded_python3_provider = 0
let g:loaded_ruby_provider = 0
let g:loaded_perl_provider = 0
let g:loaded_node_provider = 0
