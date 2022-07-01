local gs = require('gitsigns')

gs.setup {
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
  signcolumn = false,
  numhl = false,
  linehl = false,
  on_attach = function(bufnr)
    local opts = {buffer = bufnr, expr = true}

    vim.keymap.set(
      'n',
      '[c',
      function()
        if vim.wo.diff then return '[c' end
        vim.schedule(function() gs.prev_hunk() end)
        return '<Ignore>'
      end,
      opts
    )
    vim.keymap.set(
      'n',
      ']c',
      function()
        if vim.wo.diff then return ']c' end
        vim.schedule(function() gs.next_hunk() end)
        return '<Ignore>'
      end,
      opts
    )
  end
}
