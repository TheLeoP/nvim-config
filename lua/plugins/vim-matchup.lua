return {
  "andymass/vim-matchup",
  init = function()
    vim.g.matchup_delim_noskips = 1 -- recognize only symbols in strings and comments
    vim.g.matchup_matchparen_offscreen = {} -- disable feature
    vim.g.matchup_matchparen_deferred = 1
  end,
}
