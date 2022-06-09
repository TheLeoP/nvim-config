set number  "muestra los números de las lineas en el lado izquierdo
set relativenumber  "muestra los números relativos a la izquierda
set nowrap  "las líneas largas se muestran como una sola línea

set noswapfile  "configura vim para no crear archivos .swap
set nobackup    "configura vim para no crear archivos de respaldo
set nowritebackup
set undofile    "conigura vim para sí crear archivos de deshacer/rehacer
set clipboard=unnamedplus   "permite que todo lo copiado vaya también al clipboard del sistema

set termguicolors   "creo que permite asignar colores a la terminal (?)

set conceallevel=0

set nohlsearch  "no resalta todos los resultados de una búsqueda
set ignorecase  "case insensitive cuando se busca en minúsculas
set smartcase   "case sensitive cuando se busca en mayúsculas
" set inccommand=split " mostar cambios que hará el comando a escribir mientras se escribe

set smarttab
set expandtab

set scrolloff=8
set cmdheight=2 "número de líneas para la consola

set noshowmode  "no muestra el modo de vim (actualmente tengo un plug-in instalado que muestra esa y otra información)
set colorcolumn=80  "distancia a la que está la columna gris
set signcolumn=yes:2

set updatetime=300

if has('win32')
	set undodir=~/undodir    "señala el directorio en el cual guardar los archivos de deshacer/rehacer
	let &guifont = 'UbuntuMono NF:h15'
else
	let &guifont = 'UbuntuMono NF:h10'
endif

" lua
let g:vimsyn_embed = 'l'

if executable('rg')
	set grepprg=rg\ --vimgrep\ --hidden
endif

" autocompletion
set shortmess+=c

" mouse
set mouse=a

" split
set splitbelow
set splitright

set laststatus=3

set cursorline

set timeoutlen=300
let g:cursorhold_updatetime = 100

