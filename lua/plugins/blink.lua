local api = vim.api
return {
  "saghen/blink.cmp",

  -- use a release tag to download pre-built binaries
  version = "1.*",
  dependencies = {
    "LuaSnip",
    {
      "Kaiser-Yang/blink-cmp-git",
      dependencies = { "nvim-lua/plenary.nvim" },
    },
  },

  ---@module "blink.cmp"
  ---@return blink.cmp.Config
  opts = {
    keymap = {
      preset = "enter",
    },
    cmdline = {
      keymap = {
        preset = "none",
        ["<down>"] = { "show_and_insert", "select_next" },
        ["<up>"] = { "select_prev", "fallback" },
        ["<cr>"] = { "accept_and_enter", "fallback" },
        ["<c-e>"] = { "cancel" },
      },
    },
    snippets = { preset = "luasnip" },
    fuzzy = {
      sorts = {
        -- shows user defined commands first
        function(a, b)
          local mode = api.nvim_get_mode().mode
          if not mode:match "^c" then return end

          local a_is_upper = a.label:sub(1, 1) == a.label:sub(1, 1):upper()
          local b_is_upper = b.label:sub(1, 1) == b.label:sub(1, 1):upper()
          if a_is_upper and not b_is_upper then
            return true
          elseif b_is_upper and not a_is_upper then
            return false
          end
        end,
        "score",
        "sort_text",
      },
    },

    completion = {
      documentation = { auto_show = true, auto_show_delay_ms = 50 },
      ghost_text = { enabled = true },
      list = {
        selection = { preselect = false, auto_insert = false },
      },
    },

    sources = {
      default = { "lsp", "path", "buffer", "git", "lazydev", "dadbod", "kinesis", "calendar" },

      per_filetype = {
        query = { "lsp", "path", "buffer", "omni" }, -- uses builtin omni completion on query files
        ["dap-repl"] = { "lsp", "path", "buffer", "omni" }, -- uses nvim-dap omni completion on query files
      },

      providers = {
        dadbod = { module = "vim_dadbod_completion.blink" },

        lazydev = {
          name = "LazyDev",
          module = "lazydev.integrations.blink",
          score_offset = 100,
        },

        git = {
          module = "blink-cmp-git",
          name = "Git",
          enabled = function() return vim.tbl_contains({ "octo", "gitcommit", "markdown" }, vim.bo.filetype) end,
        },

        kinesis = {
          module = "blink-cmp-kinesis",
        },

        calendar = {
          module = "blink-cmp-calendar",
        },

        lsp = {
          name = "LSP",
          module = "blink.cmp.sources.lsp",
          transform_items = function(_, items)
            return vim.tbl_filter(
              function(item) return item.kind ~= require("blink.cmp.types").CompletionItemKind.Keyword end,
              items
            )
          end,
        },

        path = {
          opts = {
            get_cwd = function(_) return vim.fn.getcwd() end,
          },
        },
      },
    },
  },
  opts_extend = { "sources.default" },
}
