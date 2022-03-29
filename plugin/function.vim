" lightline

function! LightlineGPS() abort
	return luaeval("require'nvim-gps'.is_available()") ?
		\ luaeval("require'nvim-gps'.get_location()") : ''
endfunction

function! LightlineFilename() abort
	let filename = expand('%:t')
	let fullpath = expand('%:p')
	let extension = expand('%:e')
	if strlen(filename) > 0 || strlen(extension) > 0
		let icon = luaeval('require"nvim-web-devicons".get_icon("' . filename . '","' . extension . '")')
		return icon . " " . fullpath
	elseif filename == ""
		return '[Sin nombre]'
	else
		return fullpath
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
