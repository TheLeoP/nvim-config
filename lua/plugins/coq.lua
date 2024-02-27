return {
  "ms-jpq/coq_nvim",
  branch = "coq",
  init = function()
    vim.opt.shortmess:append "c"

    vim.opt.completeopt = { "menuone", "noselect", "noinsert" }
    vim.opt.showmode = false

    vim.g.coq_settings = {
      auto_start = "shut-up",
      keymap = {
        recommended = false,
        jump_to_mark = "<m-,>",
        bigger_preview = "",
      },
      clients = {
        snippets = {
          warn = {},
        },
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
        preview = {
          border = { "", "", "", " ", "", "", "", " " },
        },
        ghost_text = {
          enabled = true,
        },
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
  end,
  config = function()
    vim.keymap.set("i", "<BS>", function()
      if vim.fn.pumvisible() == 1 then
        return "<C-e><BS>"
      else
        return "<BS>"
      end
    end, { expr = true, silent = true })

    vim.keymap.set("i", "<CR>", function()
      if vim.fn.pumvisible() == 1 then
        if vim.fn.complete_info().selected == -1 then
          return "<C-e><CR>"
        else
          return "<C-y>"
        end
      else
        return "<CR>"
      end
    end, { expr = true, silent = true })

    vim.keymap.set("i", "<Tab>", function()
      if vim.fn.pumvisible() == 1 then
        return "<down>"
      else
        return "<Tab>"
      end
    end, { expr = true, silent = true })

    vim.keymap.set("i", "<s-tab>", function()
      if vim.fn.pumvisible() == 1 then
        return "<up>"
      else
        return "<BS>"
      end
    end, { expr = true, silent = true })
  end,
}
