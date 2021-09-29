vim.o.completeopt = 'menuone,noselect,noinsert'
vim.o.showmode = false

vim.g.coq_settings = {
  auto_start = 'shut-up',
  keymap = {
    recommended = false,
    jump_to_mark = "<m-,>"
  },
  clients = {
    paths = {
      path_seps = {
        "/"
      }
    },
    buffers = {
      match_syms = true
    }
  },
  display = {
    ghost_text = {
      enabled = true
    },
    preview = {
      border = vim.g.lsp_borders
    }
  },
  match = {
    unifying_chars = {
      '-',
      '_',
    }
  }
}

require('coq_3p')({
  {src = "dap"}
})
