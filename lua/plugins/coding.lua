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
      ["h"] = function(widget) return widgets.sidebar(widget, nil, "topleft 50 vsplit") end,
      ["k"] = function(widget) return widgets.sidebar(widget, nil, "topleft 7 split") end,
      ["j"] = function(widget) return widgets.sidebar(widget, nil, "7 split") end,
      ["l"] = function(widget) return widgets.sidebar(widget, nil, "50 vsplit") end,
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
    if not choice then return end

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

    if not ok or char == "\27" or not char then return end
    init_location_if_required() ---@cast location -nil
    local component_by_location = location[char]
    if not component_by_location then
      vim.notify(("There is no location for char %s"):format(char), vim.log.levels.Warning)
      return
    end

    if char == "c" then
      component_by_location(components[choice])
    else
      local widget = cache[char][choice]
      if not widget then
        widget = component_by_location(components[choice])
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
  },
  {
    "zbirenbaum/copilot.lua",
    enabled = false,
    opts = {
      suggestion = {
        auto_trigger = true,
        keymap = {
          accept = "<M-f>",
          next = "<M-}>",
          prev = "<M-{>",
        },
      },
      filetypes = {
        ["dap-repl"] = false,
        c = false,
        cpp = false,
        telescopeprompt = false,
        xml = false,
        dashboard = false,
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
    dev = true,
    keys = {
      {
        "<leader>ae",
        function() require("refactoring").refactor "Extract Function" end,
        mode = "x",
      },
      {
        "<leader>af",
        function() require("refactoring").refactor "Extract Function To File" end,
        mode = "x",
      },
      {
        "<leader>av",
        function() require("refactoring").refactor "Extract Variable" end,
        mode = "x",
      },
      {
        "<leader>ai",
        function() require("refactoring").refactor "Inline Variable" end,
        mode = { "n", "x" },
      },
      {
        "<leader>abb",
        function() require("refactoring").refactor "Extract Block" end,
        mode = "n",
      },
      {
        "<leader>abf",
        function() require("refactoring").refactor "Extract Block To File" end,
        mode = "n",
      },
      {
        "<leader>apP",
        function() require("refactoring").debug.printf { below = false } end,
        mode = "n",
      },
      {
        "<leader>pp",
        function() require("refactoring").debug.printf { below = true } end,
        mode = "n",
      },
      {
        "<leader>pv",
        function() require("refactoring").debug.print_var { below = true } end,
        mode = { "x", "n" },
      },
      {
        "<leader>apV",
        function() require("refactoring").debug.print_var { below = false } end,
        mode = { "x", "n" },
      },
      {
        "<leader>pc",
        function() require("refactoring").debug.cleanup {} end,
        mode = "n",
      },
      {
        "<leader>aI",
        function() require("refactoring").refactor(115) end,
        mode = "n",
      },
    },
    opts = {},
  },
  {
    "mfussenegger/nvim-dap-python",
    lazy = false,
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
        build = "npm i && npm run compile vsDebugServerBundle &&"
          .. (vim.fn.has "win32" and "(if exist out\\ rd /s /q out)" or "rm -rf out")
          .. "&&"
          .. (vim.fn.has "win32" and "move dist out" or "mv dist out"),
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
    "/leoluz/nvim-dap-go",
    opts = {},
  },
  {
    "mfussenegger/nvim-dap",
    lazy = false,
    keys = {
      {
        "<leader>dm",
        debug_menu,
        mode = "n",
      },
      {
        "<leader>dp",
        function() require("dap.ui.widgets").preview() end,
        mode = "n",
      },
      {
        "<leader>dh",
        function() require("dap.ui.widgets").hover() end,
        mode = "n",
      },
      {
        "<leader>dc",
        function() require("dap").continue() end,
        mode = "n",
      },
      {
        "<leader>dr",
        function() require("dap").repl.toggle() end,
        mode = "n",
      },
      {
        "<leader>de",
        function() require("dap").terminate() end,
        mode = "n",
      },
      {
        "<leader>db",
        function() require("dap").toggle_breakpoint() end,
        mode = "n",
      },
      {
        "<leader>dB",
        function()
          vim.ui.input(
            { prompt = "Breakpoint condition: " },
            ---@param input string|nil
            function(input)
              if input then require("dap").set_breakpoint(input) end
            end
          )
        end,
        mode = "n",
      },
      {
        "<leader>dl",
        function()
          local open_qflist = true
          require("dap").list_breakpoints(open_qflist)
        end,
        mode = "n",
      },
      {
        "<leader>dv",
        function() require("dap").step_over() end,
        mode = "n",
      },
      {
        "<leader>dsi",
        function() require("dap").step_into() end,
        mode = "n",
      },
      {
        "<leader>dso",
        function() require("dap").step_out() end,
        mode = "n",
      },
      {
        "<leader>dsb",
        function() require("dap").step_back() end,
        mode = "n",
      },
      {
        "<leader>dtc",
        function() require("dap").run_to_cursor() end,
        mode = "n",
      },
    },
    config = function()
      vim.fn.sign_define("DapBreakpoint", { text = "⦿", texthl = "Error", linehl = "", numhl = "" })
      local dap = require "dap"

      dap.defaults.fallback.external_terminal = { command = "gnome-terminal", args = { "--" } }

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

      dap.adapters.cppdbg = {
        id = "cppdbg",
        type = "executable",
        command = require("personal.config.lsp").mason_root .. "cpptools/extension/debugAdapters/bin/OpenDebugAD7",
      }

      dap.configurations.c = {
        setmetatable({
          name = "Neovim",
          type = "cppdbg",
          request = "launch",
          cwd = "${workspaceFolder}",
          program = function()
            return vim.fn.input {
              prompt = "Path to executable: ",
              default = vim.loop.cwd() .. "/build/bin/nvim",
              completion = "file",
            }
          end,
          args = function()
            local args = vim.fn.input {
              prompt = "Args: ",
              default = "--clean -u ~/minimal.lua",
              completion = "file",
            }
            return vim.split(args, " ", { trimempty = true })
          end,

          externalConsole = true,
        }, {
          __call = function(config)
            vim.fn.system "CMAKE_BUILD_TYPE=RelWithDebInfo make"

            local key = "the-leo-p"

            -- ⬇️ `dap.listeners.<before | after>.<event_or_command>.<plugin_key>`
            -- We listen to the `initialize` response. It indicates a new session got initialized
            dap.listeners.after.initialize[key] = function(session)
              -- ⬇️ immediately clear the listener, we don't want to run this logic for additional sessions
              dap.listeners.after.initialize[key] = nil

              -- The first argument to a event or response is always the session
              -- A session contains a `on_close` table that allows us to register functions
              -- that get called when the session closes.
              -- We use this to ensure the listeners get cleaned up
              session.on_close[key] = function()
                for _, handler in pairs(dap.listeners.after) do
                  handler[key] = nil
                end
              end
            end

            -- We listen to `event_process` to get the pid:
            dap.listeners.after.event_process[key] = function(_, body)
              -- ⬇️ immediately clear the listener, we don't want to run this logic for additional sessions
              dap.listeners.after.event_process[key] = nil

              local ppid = body.systemProcessId --[[@as string]]
              -- The pid is the parent pid, we need to attach to the child. This uses the `ps` tool to get it
              -- It takes a bit for the child to arrive. This uses the `vim.wait` function to wait up to a second
              -- to get the child pid.
              vim.wait(
                1000,
                function() return tonumber(vim.fn.system("ps -o pid= --ppid " .. tostring(ppid))) ~= nil end
              )
              local pid = tonumber(vim.fn.system("ps -o pid= --ppid " .. tostring(ppid)))

              -- If we found it, spawn another debug session that attaches to the pid.
              if pid then
                dap.run {
                  name = "Neovim embedded",
                  type = "cppdbg",
                  request = "attach",
                  processId = pid,
                  -- ⬇️ Change paths as needed
                  program = os.getenv "HOME" .. "/neovim/build/bin/nvim",
                  cwd = os.getenv "HOME" .. "/neovim/",
                  externalConsole = false,
                }
              end
            end

            return config
          end,
        }),
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

      dap.adapters.coreclr = {
        type = "executable",
        command = require("personal.config.lsp").mason_root .. "/netcoredbg/netcoredbg/netcoredbg",
        args = { "--interpreter=vscode" },
      }

      dap.configurations.cs = {
        {
          type = "coreclr",
          name = "launch - netcoredbg",
          request = "launch",
          program = function() return vim.fn.input("Path to dll", vim.fn.getcwd() .. "/bin/Debug/", "file") end,
        },
      }
    end,
    dependencies = {
      "jbyuki/one-small-step-for-vimkind",
      "mfussenegger/nvim-dap-python",
      "mxsdev/nvim-dap-vscode-js",
      "theHamsta/nvim-dap-virtual-text",
    },
  },
  {
    "jay-babu/mason-nvim-dap.nvim",
    opts = {
      automatic_installation = true,
    },
    dependencies = {
      "mfussenegger/nvim-dap",
      "williamboman/mason.nvim",
    },
  },
  {
    "theHamsta/nvim-dap-virtual-text",
    opts = { virt_text_pos = "eol" },
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
    end,
  },
  {
    "andymass/vim-matchup",
    init = function()
      vim.g.matchup_delim_noskips = 1 -- recognize only symbols in strings and comments
      vim.g.matchup_matchparen_offscreen = {} -- disable feature
      vim.g.matchup_matchparen_deferred = 1
    end,
  },
}
