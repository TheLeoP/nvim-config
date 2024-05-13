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

local dotnet_last_project ---@type string?
local function dotnet_build_project()
  local default_path = dotnet_last_project and dotnet_last_project or vim.fn.getcwd() .. "/"

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
local request = function() return vim.fn.input("Path to dll: ", vim.fn.getcwd() .. "/bin/Debug/", "file") end
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
    vim.fn.sign_define("DapBreakpoint", { text = "⦿", texthl = "Error", linehl = "", numhl = "" })
    local dap = require "dap"

    vim.keymap.set("n", "<leader>dm", debug_menu)
    vim.keymap.set("n", "<leader>dp", function() require("dap.ui.widgets").preview() end)
    vim.keymap.set("n", "<leader>dh", function() require("dap.ui.widgets").hover() end)
    vim.keymap.set("n", "<leader>dc", function() require("dap").continue() end)
    vim.keymap.set("n", "<leader>dr", function() require("dap").repl.toggle() end)
    vim.keymap.set("n", "<leader>de", function() require("dap").terminate() end)
    vim.keymap.set("n", "<leader>db", function() require("dap").toggle_breakpoint() end)
    vim.keymap.set("n", "<leader>dB", function()
      vim.ui.input(
        { prompt = "Breakpoint condition: " },
        ---@param input string|nil
        function(input)
          if input then require("dap").set_breakpoint(input) end
        end
      )
    end)
    vim.keymap.set("n", "<leader>dl", function() require("dap").list_breakpoints(true) end)
    vim.keymap.set("n", "<leader>dv", function() require("dap").step_over() end)
    vim.keymap.set("n", "<leader>dsi", function() require("dap").step_into() end)
    vim.keymap.set("n", "<leader>dso", function() require("dap").step_out() end)
    vim.keymap.set("n", "<leader>dsb", function() require("dap").step_back() end)
    vim.keymap.set("n", "<leader>dtc", function() require("dap").run_to_cursor() end)

    require("overseer").patch_dap(true)
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
            vim.wait(1000, function() return tonumber(vim.fn.system("ps -o pid= --ppid " .. tostring(ppid))) ~= nil end)
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
