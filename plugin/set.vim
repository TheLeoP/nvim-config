set number  "muestra los números de las lineas en el lado izquierdo
set relativenumber  "muestra los números relativos a la izquierda
set nowrap  "las líneas largas se muestran como una sola línea

set noswapfile  "configura vim para no crear archivos .swap
set nobackup    "configura vim para no crear archivos de respaldo
set nowritebackup
set undofile    "conigura vim para sí crear archivos de deshacer/rehacer
set clipboard=unnamedplus   "permite que todo lo copiado vaya también al clipboard del sistema

set termguicolors   "creo que permite asignar colores a la terminal (?)
" silent! set guifont=UbuntuMono\ NF:h15

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
set signcolumn=yes

set updatetime=300

if has('win32')
	" let &shell = 'pwsh'
	" let &shellcmdflag = '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;'
	" let &shellredir = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
	" let &shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
	" set shellquote= shellxquote=

	set undodir=~/undodir    "señala el directorio en el cual guardar los archivos de deshacer/rehacer
endif

" vim-test
let test#java#runner = 'gradletest'
let test#strategy = "dispatch"

" lua
let g:vimsyn_embed = 'l'

if executable('rg')
	set grepprg=rg\ --vimgrep\ --hidden
endif

" autocompletion
set shortmess+=c

" mouse
set mouse=a
