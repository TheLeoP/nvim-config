vim.g.lightline = {
	 active = {
	   left = {
			 {'mode'}, {'git_branch'}, {'cwd', 'file_name', 'modified'}
		 },
	   right = {
			 {'filetype'}, {'gps', 'lsp_status'}, {'tags'}
		 }
	 },
	 inactive = {
	   left = {
			 {'inactive'}, {'file_name'}
		 },
	   right = {
		 {'buf_num'}
	 }
	 },
	 component = {
	   buf_num = '%n',
	   inactive = 'inactive'
	 },
	 component_function = {
	   git_branch = 'LightlineGitBranch',
	   gps = 'LightlineGPS',
	   file_name = 'LightlineFilename',
	   lsp_status = 'LightlineLspStatus',
	   tags = 'gutentags#statusline',
		 cwd = 'LighlineCwd'
	 },
	 separator = {
	   left = '',
	   right = ''
	 },
	 subseparator = {
	   left = '|',
	   right = '|'
	 },
	 colorscheme = 'one',
}
