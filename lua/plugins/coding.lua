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
    "vim-scripts/ReplaceWithRegister",
    keys = {
      { "<leader>r", "<Plug>ReplaceWithRegisterVisual", mode = "x" },
      { "<leader>r", "<Plug>ReplaceWithRegisterOperator", mode = "n" },
      { "<leader>rr", "<Plug>ReplaceWithRegisterLine", mode = "n" },
    },
  },
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
    "github/copilot.vim",
    init = function()
      vim.g.copilot_no_tab_map = vim.v["true"]
      vim.g.copilot_filetypes = {
        ["dap-repl"] = vim.v["false"],
        ["dapui-scopes"] = vim.v["false"],
        ["dapui-breakpoints"] = vim.v["false"],
        ["dapui-stacks"] = vim.v["false"],
        ["dapui-watches"] = vim.v["false"],
        ["dapui-console"] = vim.v["false"],
      }
    end,
    config = function()
      vim.api.nvim_set_keymap("i", "<c-f>", "copilot#Accept()", { silent = true, expr = true })
      vim.keymap.set("i", "<M-{>", vim.fn["copilot#Next"])
      vim.keymap.set("i", "<M-}>", vim.fn["copilot#Previous"])
      vim.keymap.set("i", "<M-'>", vim.fn["copilot#Suggest"])

      vim.keymap.set("i", "<c-]>", vim.fn["copilot#Dismiss"])
      vim.keymap.set("i", "", vim.fn["copilot#Dismiss"])
    end,
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
    dev = vim.fn.has "win32" == 0,
    keys = {
      {
        "<leader>ae",
        function()
          vim.cmd "normal "
          require("refactoring").refactor "Extract Function"
        end,
        mode = "x",
      },
      {
        "<leader>af",
        function()
          vim.cmd "normal "
          require("refactoring").refactor "Extract Function To File"
        end,
        mode = "x",
      },
      {
        "<leader>av",
        function()
          vim.cmd "normal "
          require("refactoring").refactor "Extract Variable"
        end,
        mode = "x",
      },
      {
        "<leader>ai",
        function()
          vim.cmd "normal "
          require("refactoring").refactor "Inline Variable"
        end,
        mode = "x",
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
        "<leader>ai",
        function()
          vim.cmd "normal "
          require("refactoring").refactor "Inline Variable"
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
          require("refactoring").debug.print_var { below = true, normal = true }
        end,
        mode = "n",
      },
      {
        "<leader>apv",
        function()
          vim.cmd "normal "
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
    },
    config = true,
  },
  {
    "mfussenegger/nvim-dap-python",
    lazy = true,
    config = function()
      local mason_root = vim.fn.stdpath "data" .. "/mason/packages/"

      require("dap-python").setup(mason_root .. "debugpy/venv/Scripts/pyton.exe")
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
        "<leader>dc",
        function()
          require("dap").continue()
        end,
        mode = "n",
        silent = true,
      },
      {
        "<leader>ds",
        function()
          require("dap").continue()
        end,
        mode = "n",
        silent = true,
      },
      {
        "<leader>dr",
        function()
          require("dap").disconnect { restart = true }
        end,
        mode = "n",
        silent = true,
      },
      {
        "<leader>de",
        function()
          require("dap").terminate()
          require("dapui").close()
        end,
        mode = "n",
        silent = true,
      },
      {
        "<leader>dp",
        function()
          require("dap").pause()
        end,
        mode = "n",
        silent = true,
      },
      {
        "<leader>db",
        function()
          require("dap").toggle_breakpoint()
        end,
        mode = "n",
        silent = true,
      },
      {
        "<leader>dB",
        function()
          require("dap").set_breakpoint(vim.fn.input "Breakpoint condition: ")
        end,
        mode = "n",
        silent = true,
      },
      {
        "<leader>dv",
        function()
          require("dap").step_over()
        end,
        mode = "n",
        silent = true,
      },
      {
        "<leader>dsi",
        function()
          require("dap").step_into()
        end,
        mode = "n",
        silent = true,
      },
      {
        "<leader>dso",
        function()
          require("dap").step_out()
        end,
        mode = "n",
        silent = true,
      },
      {
        "<leader>dsb",
        function()
          require("dap").step_back()
        end,
        mode = "n",
        silent = true,
      },
      {
        "<leader>dtc",
        function()
          require("dap").run_to_cursor()
        end,
        mode = "n",
        silent = true,
      },
    },
    config = function()
      vim.fn.sign_define("DapBreakpoint", { text = "⦿", texthl = "Error", linehl = "", numhl = "" })
      local dap = require "dap"
      local dapui = require "dapui"
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

      dapui.setup()

      dap.listeners.after.event_initialized["dapui_config"] = function()
        dapui.open()
      end
    end,
    dependencies = {
      "jbyuki/one-small-step-for-vimkind",
      "mfussenegger/nvim-dap-python",
      "rcarriga/nvim-dap-ui",
      "mxsdev/nvim-dap-vscode-js",
    },
  },
  {
    "andymass/vim-matchup",
    init = function()
      vim.g.loaded_matchit = 1
      vim.g.matchup_matchparen_offscreen = {
        method = "popup",
      }
    end,
  },
  {
    "danymat/neogen",
    config = true,
    keys = {
      { "<leader>gf", "<cmd>Neogen func<cr>", mode = "n" },
      { "<leader>gF", "<cmd>Neogen file<cr>", mode = "n" },
      { "<leader>gc", "<cmd>Neogen class<cr>", mode = "n" },
      { "<leader>gt", "<cmd>Neogen type<cr>", mode = "n" },
    },
  },
}
