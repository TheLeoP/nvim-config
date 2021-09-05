vim.g.lightline = {
	 active = {
	   left = {
			 {'mode', 'paste'}, {'gitbranch'}, {'filename', 'modified'}
		 },
	   right = {
			 {'filetype', 'percent', 'lineinfo'}, {'gps'}
		 }
	 },
	 inactive = {
	   left = {
			 {'inactive'}, {'filename'}
		 },
	   right = {
		 {'bufnum'}
	 }
	 },
	 component = {
	   bufnum = '%n',
	   inactive = 'inactive'
	 },
	 component_function = {
	   gitbranch = 'LightLineGitBranch',
	   gps = 'LightlineGPS',
	   filename = 'LightlineFilename',
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
