vim.o.completeopt = "menuone,noselect,noinsert"
vim.o.showmode = false

vim.g.coq_settings = {
  auto_start = "shut-up",
  keymap = {
    recommended = false,
    jump_to_mark = "<m-,>",
  },
  clients = {
    paths = {
      path_seps = {
        "/",
      },
    },
    buffers = {
      match_syms = false,
    },
    third_party = {
      enabled = false,
    },
    lsp = {
      weight_adjust = 1,
    },
  },
  display = {
    ghost_text = {
      enabled = true,
    },
    -- preview = {
    --   border = vim.g.lsp_borders,
    -- },
    pum = {
      fast_close = false,
    },
  },
  match = {
    unifying_chars = {
      "-",
      "_",
    },
  },
  limits = {
    completion_auto_timeout = 1.0,
    completion_manual_timeout = 1.0,
  },
}

-- require "coq_3p" {
--   -- {
--   --   src = "dap"
--   -- },
--   {
--     src = "nvimlua",
--     short_name = "nLUA",
--     conf_only = false,
--   },
-- }
