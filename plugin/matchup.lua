-- recognize only symbols in strings and comments (and not words like `for` or
-- `end`)
vim.g.matchup_delim_noskips = 1
-- disable feature
vim.g.matchup_matchparen_offscreen = {}
vim.g.matchup_matchparen_deferred = 1
vim.g.matchup_mouse_enabled = 0

vim.g.matchup_matchparen_nomode = "i"

vim.pack.add { "https://github.com/andymass/vim-matchup" }
