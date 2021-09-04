set number  "muestra los números de las lineas en el lado izquierdo
set relativenumber  "muestra los números relativos a la izquierda
set nowrap  "las líneas largas se muestran como una sola línea
set hidden  "permite cerrar/cambiar buffers sin grabar primero

set noswapfile  "configura vim para no crear archivos .swap
set nobackup    "configura vim para no crear archivos de respaldo
set nowritebackup
set undofile    "conigura vim para sí crear archivos de deshacer/rehacer
set clipboard=unnamedplus   "permite que todo lo copiado vaya también al clipboard del sistema

set termguicolors   "creo que permite asignar colores a la terminal (?)

set conceallevel=0
set t_Co=256

set nohlsearch  "no resalta todos los resultados de una búsqueda
set ignorecase  "case insensitive cuando se busca en minúsculas
set smartcase   "case sensitive cuando se busca en mayúsculas
set inccommand=split " mostar cambios que hará el comando a escribir mientras se escribe

set smarttab
set expandtab

set scrolloff=8
set cmdheight=2 "número de líneas para la consola

set noshowmode  "no muestra el modo de vim (actualmente tengo un plug-in instalado que muestra esa y otra información)
set colorcolumn=80  "distancia a la que está la columna gris
set signcolumn=yes

set updatetime=300

if has('win32')
	let &shell = 'pwsh'
	let &shellcmdflag = '-NoLogo -NoProfile -ExecutionPolicy RemoteSigned -Command [Console]::InputEncoding=[Console]::OutputEncoding=[System.Text.Encoding]::UTF8;'
	let &shellredir = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
	let &shellpipe = '2>&1 | Out-File -Encoding UTF8 %s; exit $LastExitCode'
	set shellquote= shellxquote=

	set undodir=~/undodir    "señala el registro en el cual guardar los archivos de deshacer/rehacer
endif

" vim-test
let test#java#runner = 'gradletest'
let test#strategy = "dispatch"

" lua
let g:vimsyn_embed = 'l'

if executable('rg')
	set grepprg=rg\ --vimgrep\ --hidden
endif

" lightline

function! LightlineGPS() abort
	return luaeval("require'nvim-gps'.is_available()") ?
		\ luaeval("require'nvim-gps'.get_location()") : ''
endfunction

function! LightlineFilename() abort
	let filename = expand('%:t')
	let extension = expand('%:e')
	if strlen(filename) > 0 && strlen(extension) > 0
		let icon = luaeval('require"nvim-web-devicons".get_icon("' . filename . '","' . extension . '")')
		return icon . " " . filename
	else
		return '[Sin nombre]'
	endif
endfunction

function! LightLineGitBranch() abort
	let branch = fugitive#head()
	if strlen(branch) > 0
		return ' ' . branch
	else
		return branch
	endif
endfunction

let g:lightline = {
	\ 'active': {
	\   'left': [['mode', 'paste'], ['gitbranch'], ['filename', 'modified']],
	\   'right': [['filetype', 'percent', 'lineinfo'], ['gps']]
	\ },
	\ 'inactive': {
	\   'left': [['inactive'], ['filename']],
	\   'right': [['bufnum']]
	\ },
	\ 'component': {
	\   'bufnum': '%n',
	\   'inactive': 'inactive'
	\ },
	\ 'component_function': {
	\   'gitbranch': 'LightLineGitBranch',
	\   'gps': 'LightlineGPS',
	\   'filename': 'LightlineFilename',
	\ },
	\ 'separator': {
	\   'left': '',
	\   'right': ''
	\ },
	\ 'subseparator': {
	\   'left': '|',
	\   'right': '|'
	\ },
	\ 'colorscheme': 'one',
	\}

" autocompletion
set shortmess+=c
