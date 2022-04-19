" lightline

function! LightlineGPS() abort
	return luaeval("require'nvim-gps'.is_available()") ?
		\ luaeval("require'nvim-gps'.get_location()") : ''
endfunction

function! LightlineFilename() abort
	let filename = expand('%:t')
	let fullpath = substitute(expand('%:p'), '/', '\\', 'g')
	let extension = expand('%:e')

	if filename != ""
		let cwd = substitute(getcwd(), '/', '\\', 'g')
		let relativePath = split(fullpath, substitute(cwd, '\\', '\\\\', 'g') . '\\')[0]
		let icon = luaeval('require"nvim-web-devicons".get_icon("' . filename . '","' . extension . '")')

		if match(relativePath, '\\\|\/') > 0
			let partialFullPath = join(map(split(fnamemodify(relativePath, ':h'), '\\\|\/'), 'v:val[0:1]'), '/')
			let relativePath = partialFullPath . '/' . filename
		endif

		return icon . " " . relativePath
	else
		return '[Sin nombre]'
	endif
endfunction

function! LightlineGitBranch() abort
	let branch = fugitive#head()
	if strlen(branch) > 0
		return ' ' . branch
	else
		return branch
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
