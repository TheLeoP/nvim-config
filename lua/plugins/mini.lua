return {
  "echasnovski/mini.nvim",

  version = false,
  dependencies = {
    "nvim-treesitter-textobjects",
    {
      "JoosepAlviste/nvim-ts-context-commentstring",
      opts = {
        enable_autocmd = false,
      },
    },
  },
  config = function()
    local ai = require "mini.ai"
    local gen_ai_spec = require("mini.extra").gen_ai_spec

    ai.setup {
      n_lines = 500,
      custom_textobjects = {
        o = ai.gen_spec.treesitter({
          a = { "@block.outer", "@conditional.outer", "@loop.outer" },
          i = { "@block.inner", "@conditional.inner", "@loop.inner" },
        }, {}),
        f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
        c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
        F = ai.gen_spec.treesitter { a = "@call.outer", i = "@call.inner" },
        t = { "<([%p%w]-)%f[^<%w][^<>]->.-</%1>", "^<.->().*()</[^/]->$" },

        B = gen_ai_spec.buffer(),
        d = gen_ai_spec.diagnostic(),
        i = gen_ai_spec.indent(),
        l = gen_ai_spec.line(),
        n = gen_ai_spec.number(),
        P = function()
          local start_row, start_col = unpack(vim.api.nvim_buf_get_mark(0, "[")) --[[@as integer, integer]]
          local end_row, end_col = unpack(vim.api.nvim_buf_get_mark(0, "]")) --[[@as integer, integer]]
          local vis_mode = vim.fn.getregtype '"'
          if #vis_mode > 1 then vis_mode = vis_mode:sub(1, 1) end
          local region = {
            from = { line = start_row, col = start_col + 1 },
            to = { line = end_row, col = end_col + 1 },
            vis_mode = vis_mode,
          }
          return region
        end,
      },
      mappings = {
        goto_left = "g{",
        goto_right = "g}",
        around_next = "",
        inside_next = "",
        around_last = "",
        inside_last = "",
      },
    }

    require("mini.align").setup {
      modifiers = {
        I = function(steps, _)
          local pattern = vim.fn.input { prompt = "Ignore pattern: " }
          if pattern == nil then return end
          table.insert(steps.pre_split, MiniAlign.gen_step.ignore_split { pattern })
        end,
      },
    }
    require("mini.move").setup {
      mappings = {
        line_right = "",
        line_left = "",
      },
    }
    require("mini.operators").setup {
      sort = {
        prefix = "",
      },
      replace = {
        prefix = "<leader>r",
      },
      exchange = {
        prefix = "<leader>x",
      },
    }
    local mini_misc = require "mini.misc"
    mini_misc.setup()
    -- The OSC codes break firenvim comunication
    -- ConPTY (Windows) does not support querying for bg/fg colors (OSC 11, 12)
    -- https://github.com/microsoft/terminal/issues/3718
    if not vim.g.started_by_firenvim and vim.fn.has "win32" == 0 then mini_misc.setup_termbg_sync() end
    require("mini.surround").setup {
      mappings = {
        add = "<leader>s",
        delete = "<leader>sd",
        find = "",
        find_left = "",
        highlight = "<leader>sh",
        replace = "<leader>sc",
        update_n_lines = "<leader>sn",
      },

      n_lines = 100,
    }

    require("mini.comment").setup {
      options = {
        custom_commentstring = function()
          return require("ts_context_commentstring.internal").calculate_commentstring() or vim.bo.commentstring
        end,
      },
    }

    require("mini.hipatterns").setup {
      highlighters = {
        fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
        hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
        todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
        note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
      },
    }

    require("mini.notify").setup {
      lsp_progress = {
        duration_last = 500,
      },
      window = {
        config = function()
          local has_statusline = vim.o.laststatus > 0
          local pad = vim.o.cmdheight + (has_statusline and 1 or 0)
          return { anchor = "SE", col = vim.o.columns, row = vim.o.lines - pad }
        end,
        max_width_share = 0.25,
      },
    }
  end,
}
