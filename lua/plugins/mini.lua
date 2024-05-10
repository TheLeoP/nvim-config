return {
  "echasnovski/mini.nvim",

  version = false,
  dependencies = { "nvim-treesitter-textobjects" },
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
        D = gen_ai_spec.diagnostic(),
        I = gen_ai_spec.indent(),
        L = gen_ai_spec.line(),
        N = gen_ai_spec.number(),
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
    require("mini.misc").setup()
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

      n_lines = 20,
    }

    vim.keymap.set("x", "<leader>s", [[:<C-u>lua MiniSurround.add('visual')<CR>]], { silent = true })

    require("mini.comment").setup {}

    require("mini.hipatterns").setup {
      highlighters = {
        -- Highlight standalone 'FIXME', 'HACK', 'TODO', 'NOTE'
        fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
        hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
        todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
        note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
      },
    }

    require("mini.notify").setup()
  end,
}
