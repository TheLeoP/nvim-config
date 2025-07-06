local keymap = vim.keymap

local dotnet_last_project ---@type string?
local function dotnet_build_project()
  local default_path = dotnet_last_project or vim.uv.cwd() .. "/"

  local path = vim.fn.input("Path to your *proj file: ", default_path, "file")
  dotnet_last_project = path
  local cmd = { "dotnet", "build", "-c", "Debug", path }
  vim.notify(([[Cmd to execute: %s]]):format(table.concat(cmd, " ")))
  local result = vim.system(cmd):wait()
  if result.code == 0 then
    vim.notify "Build: ✔️ "
  else
    vim.notify(("Build: ❌ (error: %s)"):format(result.stderr))
  end
end

local dotnet_last_dll ---@type string|nil
---@return string
local request = function()
  return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file")
end
local function dotnet_get_dll_path()
  if
    not dotnet_last_dll
    or vim.fn.confirm(("Do you want to change the path to dll?\n%s"):format(dotnet_last_dll), "&yes\n&no", 2) == 1
  then
    dotnet_last_dll = request()
  end

  return dotnet_last_dll
end

local last_args ---@type string[]|nil
---@return string[]
local function args()
  if
    not last_args
    or vim.fn.confirm(
        ("Do you want to change the last args?\n%s"):format(table.concat(last_args, " ")),
        "&yes\n&no",
        2
      )
      == 1
  then
    local args_string = vim.fn.input("args: ", "", "file")
    last_args = vim.split(args_string, " +")
  end
  return last_args
end

return {
  "mfussenegger/nvim-dap",
  config = function()
    local dap = require "dap"
    local dapui = require "dapui"
    vim.fn.sign_define("DapBreakpoint", { text = "⦿", texthl = "Error", linehl = "", numhl = "" })

    dap.defaults.fallback.external_terminal = {
      command = "/usr/bin/wezterm",
      args = { "start", "--" },
    }

    keymap.set({ "n", "x" }, "<leader>da", ":DapEval<cr>", { desc = "Debug ev[a]l" })
    keymap.set("n", "<leader>dh", function()
      require("dap.ui.widgets").hover()
    end, { desc = "Debug hover" })
    keymap.set("n", "<leader>dc", function()
      dap.continue()
    end, { desc = "Debug continue" })
    keymap.set(
      "n",
      "<leader>te",
      -- NOTE: the cmd is a workaround for focusing the repl when openning
      function()
        dap.repl.toggle({ height = 5 }, "aboveleft split | wincmd w")
      end,
      { desc = "Toggle DAP R[E]PL" }
    )
    keymap.set("n", "<leader>de", function()
      dap.terminate()
      dapui.close()
    end, { desc = "Debug end" })
    keymap.set("n", "<leader>db", function()
      dap.toggle_breakpoint()
    end, { desc = "Debug toggle breakpoint" })
    keymap.set("n", "<leader>dB", function()
      vim.ui.input(
        { prompt = "Breakpoint condition: " },
        ---@param input string|nil
        function(input)
          if input then dap.set_breakpoint(input) end
        end
      )
    end, { desc = "Debug toggle condition breakpoint" })
    keymap.set("n", "<leader>dq", function()
      dap.list_breakpoints(true)
    end, { desc = "Debug breakpoints to qf" })
    keymap.set("n", "<leader>dv", function()
      dap.step_over()
    end, { desc = "Debug step over" })
    keymap.set("n", "<leader>dsi", function()
      dap.step_into()
    end, { desc = "Debuf step into" })
    keymap.set("n", "<leader>dso", function()
      dap.step_out()
    end, { desc = "Debug step out" })
    keymap.set("n", "<leader>dsb", function()
      dap.step_back()
    end, { desc = "Debug step back" })
    keymap.set("n", "<leader>dtc", function()
      dap.run_to_cursor()
    end, { desc = "Debug to cursor" })

    dap.listeners.after.event_initialized["dapui_config"] = function()
      dapui.open {}
    end
    dap.listeners.before.event_terminated["dapui_config"] = function()
      dapui.close {}
    end
    dap.listeners.before.event_exited["dapui_config"] = function()
      dapui.close {}
    end

    require("dap.ext.vscode").json_decode = require("overseer.json").decode

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

    local mason_root = require("personal.config.lsp").mason_root
    dap.adapters.cppdbg = {
      id = "cppdbg",
      type = "executable",
      command = mason_root .. "cpptools/extension/debugAdapters/bin/OpenDebugAD7",
    }

    dap.configurations.c = {
      setmetatable({
        name = "Neovim",
        type = "cppdbg",
        request = "launch",
        cwd = "${workspaceFolder}",
        program = function()
          return coroutine.create(function(dap_run_co)
            vim.ui.input({
              prompt = "Path to executable: ",
              default = vim.uv.cwd() .. "/build/bin/nvim",
              completion = "file",
            }, function(choice)
              if not choice then
                coroutine.resume(dap_run_co, dap.ABORT)
                return
              end
              coroutine.resume(dap_run_co, choice)
            end)
          end)
        end,
        args = function()
          return coroutine.create(function(dap_run_co)
            vim.ui.input({
              prompt = "Args: ",
              default = "--clean",
              completion = "file",
            }, function(args)
              if not args then
                coroutine.resume(dap_run_co, dap.ABORT)
                return
              end
              coroutine.resume(dap_run_co, vim.split(args, " ", { trimempty = true }))
            end)
          end)
        end,

        externalConsole = true,
      }, {
        __call = function(config)
          local co = coroutine.running()

          vim.notify "Building Neovim"
          vim.system({ "make", "CMAKE_BUILD_TYPE=RelWithDebInfo" }, nil, function(out)
            coroutine.resume(co, out)
          end)
          ---@type vim.SystemCompleted
          local out = coroutine.yield(co)
          vim.notify "Done building"
          if out.stderr ~= "" then
            vim.notify(out.stderr, vim.log.levels.ERROR)
            return
          end

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
            vim.wait(1000, function()
              return tonumber(vim.fn.system("ps -o pid= --ppid " .. tostring(ppid))) ~= nil
            end)
            local pid = tonumber(vim.fn.system("ps -o pid= --ppid " .. tostring(ppid)))

            -- If we found it, spawn another debug session that attaches to the pid.
            if pid then
              dap.run {
                name = "Neovim embedded",
                type = "cppdbg",
                request = "attach",
                processId = pid,
                program = vim.env.HOME .. "/neovim/build/bin/nvim",
                cwd = vim.env.HOME .. "/neovim/",
                externalConsole = false,
              }
            end
          end

          vim.schedule(function()
            coroutine.resume(co)
          end)
          coroutine.yield()
          return config
        end,
      }),
      setmetatable({
        name = "make",
        type = "cppdbg",
        request = "launch",
        cwd = "${workspaceFolder}",
        program = function()
          return coroutine.create(function(dap_run_co)
            vim.ui.input({
              prompt = "Path to executable: ",
              default = vim.uv.cwd() .. "/bin/release/main",
              completion = "file",
            }, function(choice)
              if not choice then
                coroutine.resume(dap_run_co, dap.ABORT)
                return
              end
              coroutine.resume(dap_run_co, choice)
            end)
          end)
        end,
        args = function()
          return coroutine.create(function(dap_run_co)
            vim.ui.input({
              prompt = "Args: ",
              default = "",
              completion = "file",
            }, function(args)
              if not args then
                coroutine.resume(dap_run_co, dap.ABORT)
                return
              end
              coroutine.resume(dap_run_co, vim.split(args, " ", { trimempty = true }))
            end)
          end)
        end,

        externalConsole = true,
      }, {
        __call = function(config)
          local co = coroutine.running()

          vim.notify "Running make"
          vim.system({ "make" }, nil, function(out)
            coroutine.resume(co, out)
          end)
          ---@type vim.SystemCompleted
          local out = coroutine.yield(co)
          vim.notify "Done building"
          if out.stderr ~= "" then
            -- vim.notify(out.stderr, vim.log.levels.ERROR)
            return
          end
          vim.schedule(function()
            coroutine.resume(co)
          end)
          coroutine.yield()
          return config
        end,
      }),
    }

    dap.adapters["pwa-node"] = {
      type = "server",
      host = "localhost",
      port = "${port}",
      executable = {
        command = "node",
        args = {
          mason_root .. "js-debug-adapter/js-debug/src/dapDebugServer.js",
          "${port}",
        },
      },
    }
    dap.adapters["node"] = function(cb, config)
      if config.type == "node" then config.type = "pwa-node" end
      local nativeAdapter = dap.adapters["pwa-node"]
      if type(nativeAdapter) == "function" then
        nativeAdapter(cb, config)
      else
        cb(nativeAdapter)
      end
    end

    local js_filetypes = { "typescript", "javascript", "svelte", "vue", "typescriptreact", "javascriptreact" }

    local vscode = require "dap.ext.vscode"
    vscode.type_to_filetypes["node"] = js_filetypes
    vscode.type_to_filetypes["pwa-node"] = js_filetypes

    for _, language in ipairs(js_filetypes) do
      dap.configurations[language] = dap.configurations[language] or {}

      if language == "javascript" then
        table.insert(dap.configurations[language], {
          type = "pwa-node",
          request = "launch",
          name = "Launch",
          program = "${file}",
          cwd = "${workspaceFolder}",
        })
      elseif language == "typescript" then
        table.insert(dap.configurations[language], {
          type = "pwa-node",
          request = "launch",
          name = "Launch tsx",
          program = "${file}",
          cwd = "${workspaceFolder}",
          runtimeExecutable = "tsx",
          skipFiles = { "<node_internals>/**", "${workspaceFolder}/node_modules/**" },

          console = "integratedTerminal",
          internalConsoleOptions = "neverOpen",
        })
      end

      table.insert(dap.configurations[language], {
        type = "pwa-node",
        request = "attach",
        name = "Attach",
        processId = require("dap.utils").pick_process,
        cwd = "${workspaceFolder}/src",
        skipFiles = { "${workspaceFolder}/node_modules/**/*.js" },

        sourceMaps = true,
        resolveSourceMapsLoations = { "${workspaceFolder}/**", "!**/node_modules/**" },
      })
    end

    dap.adapters.coreclr = {
      type = "executable",
      command = mason_root .. "/netcoredbg/netcoredbg/netcoredbg",
      args = { "--interpreter=vscode" },
    }

    dap.configurations.cs = {
      {
        type = "coreclr",
        name = "launch",
        request = "launch",
        program = function()
          if vim.fn.confirm("Should I recompile first?", "&yes\n&no", 2) == 1 then dotnet_build_project() end
          return dotnet_get_dll_path()
        end,
        cwd = "${workspaceFolder}",
      },
      {
        type = "coreclr",
        name = "launch with args",
        request = "launch",
        program = function()
          if vim.fn.confirm("Should I recompile first?", "&yes\n&no", 2) == 1 then dotnet_build_project() end
          return dotnet_get_dll_path()
        end,
        args = args,
        cwd = "${workspaceFolder}",
      },
    }
  end,
  dependencies = {
    "overseer.nvim",
    "one-small-step-for-vimkind",
    "nvim-dap-python",
    "nvim-dap-vscode-js",
    "nvim-dap-virtual-text",
  },
}
