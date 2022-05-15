" lightline

function! LightlineGPS() abort
	return luaeval("require'nvim-gps'.is_available()") ?
		\ luaeval("require'nvim-gps'.get_location()") : ''
endfunction

function! LightlineFilename() abort
	let filename = expand('%:t')
	let extension = expand('%:e')
	let fullpath = substitute(expand('%:p'), '/', '\\', 'g')

	if fullpath != ""
		let cwd = substitute(getcwd(), '/', '\\', 'g')
		let relativePath = ''

		if fullpath[:-2] != cwd
			let cwd = substitute(cwd, '\\', '\\\\', 'g')
			let relativePath = split(fullpath, cwd . '\\')[0]
		else
			let relativePath = cwd
	  	endif

		let icon = luaeval('require"nvim-web-devicons".get_icon("' . filename . '","' . extension . '")')

		if match(relativePath, '\\\|\/') && relativePath != cwd
			let partialFullPath = join(map(split(fnamemodify(relativePath, ':h'), '\\\|\/'), 'v:val[0:1]'), '/')
			let relativePath = partialFullPath . '/' . filename
		else
			let relativePath = '.'
		endif

		return icon . " " . relativePath
	else
		return '[Sin nombre]'
	endif
endfunction

function! LightlineGitBranch() abort
	let branch = FugitiveHead()
	if strlen(branch) > 0
		return ' ' . branch
	else
		return ''
	endif
endfunction

function! LightlineLspStatus() abort
	if luaeval('#vim.lsp.buf_get_clients() > 0')
    return luaeval("require('lsp-status').status()")
  endif

  return ''
endfunction

function! LighlineCwd() abort
	let cwd = getcwd()
	if match(cwd, '\')
		let cwd = substitute(cwd, '\', '/', 'g')
	endif
	return cwd . '/'
endfunction
