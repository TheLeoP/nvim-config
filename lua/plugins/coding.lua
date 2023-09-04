---@type table<string, table>|nil
local components
local init_components_if_required = function()
  local widgets = require "dap.ui.widgets"
  if not components then
    components = {
      ["sessions"] = widgets.sessions,
      ["scopes"] = widgets.scopes,
      ["frames"] = widgets.frames,
      ["expression"] = widgets.expression,
      ["threads"] = widgets.threads,
    }
  end
end

---@type table<string, fun(widget:any, winopts:any):table>|nil
local location
local init_location_if_required = function()
  local widgets = require "dap.ui.widgets"
  if not location then
    location = {
      ["h"] = function(widget)
        return widgets.sidebar(widget, nil, "topleft 50 vsplit")
      end,
      ["k"] = function(widget)
        return widgets.sidebar(widget, nil, "topleft 7 split")
      end,
      ["j"] = function(widget)
        return widgets.sidebar(widget, nil, "7 split")
      end,
      ["l"] = function(widget)
        return widgets.sidebar(widget, nil, "50 vsplit")
      end,
      ["c"] = widgets.centered_float,
    }
  end
end

---@type table<string, table<string, table>>
local cache = {
  ["h"] = {},
  ["k"] = {},
  ["j"] = {},
  ["l"] = {},
  ["c"] = {},
}

local function debug_menu()
  init_components_if_required() ---@cast components -nil
  vim.ui.select(vim.tbl_keys(components), { prompt = "Select debug widget:" }, function(choice)
    local separator = { " | ", "WarningMsg" }

    vim.cmd [[echo '' | redraw]]

    --stylua: ignore
    vim.api.nvim_echo({
      {"h", "Question"}, {": left"},
      separator,
      {"l", "Question"}, {": right"},
      separator,
      {"k", "Question"}, {": up"},
      separator,
      {"j", "Question"}, {": down"}
    }, false, {})

    local ok, char = pcall(vim.fn.getcharstr)
    vim.cmd [[echo '' | redraw]]

    if not ok or char == "\27" then
      return
    end

    init_location_if_required() ---@cast location -nil
    if char == "c" then
      location[char](components[choice])
    else
      local widget = cache[char][choice]
      if not widget then
        widget = location[char](components[choice])
        cache[char][choice] = widget
      end
      widget.toggle()
    end
  end)
end

return {
  "tpope/vim-sleuth",
  {
    "tpope/vim-dispatch",
    lazy = false,
    keys = {
      { "¿<cr>", "<cmd>Dispatch<cr>", mode = "n" },
      { "¿<space>", ":Dispatch<space>", mode = "n" },
      { "¿!", ":Dispatch!<space>", mode = "n" },
      { "¿?", "<cmd>FocusDispatch<cr>", mode = "n" },
    },
  },
  "tpope/vim-commentary",
  {
    "kana/vim-textobj-line",
    dependencies = {
      "kana/vim-textobj-user",
    },
  },
  {
    "tpope/vim-surround",
    keys = {
      { "<leader>s", "<Plug>Ysurround", noremap = false, mode = "n" },
      { "<leader>S", "<Plug>YSurround", noremap = false, mode = "n" },
      { "<leader>sd", "<Plug>Dsurround", noremap = false, mode = "n" },
      { "<leader>sc", "<Plug>Csurround", noremap = false, mode = "n" },
      { "<leader>sC", "<Plug>CSurround", noremap = false, mode = "n" },
      { "<leader>s", "<Plug>VSurround", noremap = false, mode = "x" },
      { "<leader>S", "<Plug>VgSurround", noremap = false, mode = "x" },
    },
    init = function()
      vim.g.surround_no_mappings = 1
    end,
  },
  {
    "ms-jpq/coq_nvim",
    branch = "coq",
    init = function()
      vim.opt.shortmess:append "c"

      vim.o.completeopt = "menuone,noselect,noinsert"
      vim.o.showmode = false

      vim.g.coq_settings = {
        auto_start = "shut-up",
        keymap = {
          recommended = false,
          jump_to_mark = "<m-,>",
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
  },
  {
    "zbirenbaum/copilot.lua",
    opts = {
      suggestion = {
        auto_trigger = true,
        keymap = {
          accept = "<c-f>",
          next = "<M-}>",
          prev = "<M-{>",
        },
      },
      filetypes = {
        ["dap-repl"] = false,
        telescopeprompt = false,
      },
    },
  },
  {
    "kristijanhusak/vim-dadbod-ui",
    init = function()
      vim.g.db_ui_force_echo_notifications = 1
      vim.g.db_ui_show_database_icon = 1
    end,
    dependencies = {
      "tpope/vim-dadbod",
    },
  },
  {
    "theprimeagen/refactoring.nvim",
    lazy = false,
    enabled = true,
    dev = true,
    keys = {
      {
        "<leader>ae",
        function()
          require("refactoring").refactor "Extract Function"
        end,
        mode = "x",
      },
      {
        "<leader>af",
        function()
          require("refactoring").refactor "Extract Function To File"
        end,
        mode = "x",
      },
      {
        "<leader>av",
        function()
          require("refactoring").refactor "Extract Variable"
        end,
        mode = "x",
      },
      {
        "<leader>ai",
        function()
          require("refactoring").refactor "Inline Variable"
        end,
        mode = { "n", "x" },
      },
      {
        "<leader>abb",
        function()
          require("refactoring").refactor "Extract Block"
        end,
        mode = "n",
      },
      {
        "<leader>abf",
        function()
          require("refactoring").refactor "Extract Block To File"
        end,
        mode = "n",
      },
      {
        "<leader>apP",
        function()
          require("refactoring").debug.printf { below = false }
        end,
        mode = "n",
      },
      {
        "<leader>app",
        function()
          require("refactoring").debug.printf { below = true }
        end,
        mode = "n",
      },
      {
        "<leader>apv",
        function()
          require("refactoring").debug.print_var { below = true }
        end,
        mode = { "x", "n" },
      },
      {
        "<leader>apv",
        function()
          require("refactoring").debug.print_var { below = true }
        end,
        mode = "x",
      },
      {
        "<leader>ac",
        function()
          require("refactoring").debug.cleanup {}
        end,
        mode = "n",
      },
      {
        "<leader>aI",
        function()
          require("refactoring").refactor(115)
        end,
        mode = "n",
      },
    },
    opts = {},
  },
  {
    "mfussenegger/nvim-dap-python",
    lazy = true,
    config = function()
      ---@type string
      local mason_root = vim.fn.stdpath "data" .. "/mason/packages/"

      local tail = vim.fn.has "win32" == 0 and "debugpy/venv/bin/python" or "debugpy/venv/Scripts/python.exe"
      require("dap-python").setup(mason_root .. tail)
    end,
  },
  {
    "mxsdev/nvim-dap-vscode-js",
    lazy = true,
    dependencies = {
      {
        "microsoft/vscode-js-debug",
        version = "1.x",
        build = "npm i && npm run compile vsDebugServerBundle && mv dist out",
      },
    },
    config = function()
      require("dap-vscode-js").setup {
        debugger_path = vim.fn.stdpath "data" .. "/lazy/vscode-js-debug",
        adapters = { "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" },
      }
    end,
  },
  {
    "mfussenegger/nvim-dap",
    lazy = true,
    keys = {
      {
        "<leader>dm",
        debug_menu,
        mode = "n",
      },
      {
        "<leader>dp",
        function()
          require("dap.ui.widgets").preview()
        end,
        mode = "n",
      },
      {
        "<leader>dh",
        function()
          require("dap.ui.widgets").hover()
        end,
        mode = "n",
      },
      {
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        mode = "n",
      },
      {
        "<leader>dr",
        function()
          require("dap").repl.toggle()
        end,
        mode = "n",
      },
      {
        "<leader>de",
        function()
          require("dap").terminate()
        end,
        mode = "n",
      },
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        mode = "n",
      },
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input "Breakpoint condition: ")
        end,
        mode = "n",
      },
      {
        "<leader>dv",
        function()
          require("dap").step_over()
        end,
        mode = "n",
      },
      {
        "<leader>dsi",
        function()
          require("dap").step_into()
        end,
        mode = "n",
      },
      {
        "<leader>dso",
        function()
          require("dap").step_out()
        end,
        mode = "n",
      },
      {
        "<leader>dsb",
        function()
          require("dap").step_back()
        end,
        mode = "n",
      },
      {
        "<leader>dtc",
        function()
          require("dap").run_to_cursor()
        end,
        mode = "n",
      },
    },
    config = function()
      vim.fn.sign_define("DapBreakpoint", { text = "⦿", texthl = "Error", linehl = "", numhl = "" })
      local dap = require "dap"
      dap.adapters.nlua = function(callback, config)
        callback {
          type = "server",
          host = config.host or "127.0.0.1",
          port = config.port or 8086,
        }
      end

      dap.configurations.lua = {
        {
          type = "nlua",
          request = "attach",
          name = "Attach to running Neovim instance",
        },
      }

      for _, language in ipairs { "typescript", "javascript", "svelte", "vue", "typescriptreact", "javascriptreact" } do
        dap.configurations[language] = {}
        if language == "javascript" then
          table.insert(dap.configurations[language], {
            type = "pwa-node",
            request = "launch",
            name = "Launch current file in new node process",
            program = "${file}",
            cwd = "${workspaceFolder}",
          })
        end

        table.insert(dap.configurations[language], {
          type = "pwa-node",
          request = "attach",
          processId = require("dap.utils").pick_process,
          name = "Attach debugger to existing `node --inspect` process",
          sourceMaps = true,
          resolveSourceMapsLoations = { "${workspaceFolder}/**", "!**/node_modules/**" },
          cwd = "${workspaceFolder}/src",
          skipFiles = { "${workspaceFolder}/node_modules/**/*.js" },
        })
        table.insert(dap.configurations[language], {
          type = "pwa-chrome",
          request = "launch",
          name = "Launch Chrome to debug client side code",
          url = "http://localhost:3000",
          sourceMaps = true,
          webRoot = "${workspaceFolder}/src",
          protocol = "inspector",
          port = 9222,
          skipFiles = { "${workspaceFolder}/node_modules/**/*.js", "**/@vite/*", "**/src/client/*", "**/src/*" },
        })
      end
    end,
    dependencies = {
      "jbyuki/one-small-step-for-vimkind",
      "mfussenegger/nvim-dap-python",
      "mxsdev/nvim-dap-vscode-js",
    },
  },
  {
    "danymat/neogen",
    opts = {},
    keys = {
      { "<leader>gf", "<cmd>Neogen func<cr>", mode = "n" },
      { "<leader>gF", "<cmd>Neogen file<cr>", mode = "n" },
      { "<leader>gc", "<cmd>Neogen class<cr>", mode = "n" },
      { "<leader>gt", "<cmd>Neogen type<cr>", mode = "n" },
    },
  },
  {
    "echasnovski/mini.nvim",
    lazy = false,
    version = false,
    dependencies = { "nvim-treesitter-textobjects" },
    config = function()
      local ai = require "mini.ai"

      ai.setup {
        n_lines = 500,
        custom_textobjects = {
          o = ai.gen_spec.treesitter({
            a = { "@block.outer", "@conditional.outer", "@loop.outer" },
            i = { "@block.inner", "@conditional.inner", "@loop.inner" },
          }, {}),
          f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }, {}),
          c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }, {}),
          F = ai.gen_spec.function_call(),
          t = false,
        },
        mappings = {
          around_last = "",
          inside_last = "",

          goto_left = "g{",
          goto_right = "g}",
        },
      }

      require("mini.align").setup()
      require("mini.move").setup {
        mappings = {
          line_right = "",
          line_left = "",
        },
      }
      require("mini.operators").setup {
        replace = {
          prefix = "<leader>r",
        },
        exchange = {
          prefix = "<leader>ox",
        },
      }
    end,
  },
  {
    "andymass/vim-matchup",
    init = function()
      vim.g.matchup_delim_noskips = 2 -- don't recognize anything in comments
      vim.g.matchup_matchparen_offscreen = {} -- disable feature
      vim.g.matchup_matchparen_deferred = 1
    end,
  },
}
