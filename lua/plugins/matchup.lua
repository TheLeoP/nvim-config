return {
  "theleop/vim-matchup",
  branch = "update-treesitter",
  init = function()
    vim.g.matchup_delim_noskips = 1 -- recognize only symbols in strings and comments
    vim.g.matchup_matchparen_offscreen = {} -- disable feature
    vim.g.matchup_matchparen_deferred = 1
    vim.g.matchup_mouse_enabled = 0

    vim.g.matchup_treesitter_enabled = true
  end,
}
