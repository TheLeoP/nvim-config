local methods = vim.lsp.protocol.Methods

local M = {}

M.mason_root = vim.fn.stdpath "data" .. "/mason/packages/" --[[@as string]]

M.capabilities = vim.lsp.protocol.make_client_capabilities()
M.capabilities.textDocument.completion.completionItem.snippetSupport = true
M.capabilities.textDocument.completion.completionItem.resolveSupport = {
  properties = {
    "documentation",
    "detail",
    "additionalTextEdits",
  },
}
M.capabilities.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true,
}

local lsp_group = vim.api.nvim_create_augroup("LSP", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
  group = lsp_group,
  ---@param args {buf:integer, data:{client_id:integer}}}
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end

    if client.supports_method(methods.textDocument_documentSymbol) then require("nvim-navic").attach(client, bufnr) end

    vim.keymap.set("n", "gd", function()
      if vim.bo.filetype == "cs" then
        require("personal.fzf-lua").omnisharp_lsp_definitions()
      else
        require("fzf-lua").lsp_definitions { jump_to_single_result = true }
      end
    end, { buffer = bufnr, desc = "Go to definition" })
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = bufnr, desc = "Go to declaration" })
    vim.keymap.set("n", "gr", function()
      if vim.bo.filetype == "cs" then
        require("personal.fzf-lua").omnisharp_lsp_references()
      else
        require("fzf-lua").lsp_references { jump_to_single_result = true }
      end
    end, { buffer = bufnr, desc = "Go to reference" })
    vim.keymap.set("n", "gi", function()
      if vim.bo.filetype == "cs" then
        require("personal.fzf-lua").omnisharp_lsp_implementations()
      else
        require("fzf-lua").lsp_implementations { jump_to_single_result = true }
      end
    end, { buffer = bufnr, desc = "Go to implementation" })
    vim.keymap.set("i", "<c-s>", vim.lsp.buf.signature_help, { buffer = bufnr, desc = "Signature help" })
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename" })

    vim.keymap.set({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code actions" })
    vim.keymap.set(
      "n",
      "<leader>fds",
      require("fzf-lua").lsp_document_symbols,
      { buffer = bufnr, desc = "Find document symbols" }
    )
    vim.keymap.set(
      "n",
      "<leader>fws",
      require("fzf-lua").lsp_workspace_symbols,
      { buffer = bufnr, desc = "Find workspace symbols" }
    )
    vim.keymap.set(
      "n",
      "<leader>fki",
      require("fzf-lua").lsp_incoming_calls,
      { buffer = bufnr, desc = "Find incoming calls" }
    )
    vim.keymap.set(
      "n",
      "<leader>fko",
      require("fzf-lua").lsp_outgoing_calls,
      { buffer = bufnr, desc = "Find outgoing calls" }
    )

    local inlay_hint = vim.lsp.inlay_hint
    vim.keymap.set("n", "<leader>ti", function()
      if client.supports_method(methods.textDocument_inlayHint) then inlay_hint.enable(not inlay_hint.is_enabled()) end
    end, { buffer = bufnr })
  end,
})

-- java
local on_attach_java = function()
  require("jdtls").setup_dap { hotcodereplace = "auto" }
  require("jdtls.dap").setup_dap_main_class_configs()
end

local on_init = function(client)
  if client.config.settings then
    client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
  end
end

function M.jdtls_setup()
  local jdtls_setup = require "jdtls.setup"
  local root_dir = jdtls_setup.find_root { "build.gradle", "pom.xml", "build.xml" }

  -- si no se encuentra la raíz del proyecto, se finaliza sin inicializar jdt.ls
  if not root_dir then
    vim.notify("No se ha encontrado la raíz del proyecto.\nNo se iniciará jdt.ls", vim.log.levels.WARN, {
      title = "jdt.ls status",
      timeout = 200,
    })
    return
  end

  local eclipse_wd = table.concat {
    vim.fn.stdpath "cache",
    "/java-workspace/",
    vim.fn.fnamemodify(root_dir, ":h:t"),
    "/",
    vim.fn.fnamemodify(root_dir, ":t"),
  }
  local extendedClientCapabilities = require("jdtls").extendedClientCapabilities
  extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

  local jdtls_root = M.mason_root .. "jdtls/"

  local jar = vim.fn.glob(jdtls_root .. "plugins/org.eclipse.equinox.launcher_*.jar", false, false)
  local config_location = jdtls_root .. (vim.fn.has "win32" == 1 and "config_win" or "config_linux")
  local lombok = M.mason_root .. "jdtls/lombok.jar"
  local config = {
    settings = {
      java = {
        signatureHelp = { enabled = true },
        contentProvider = { preferred = "fernflower" },
        sources = {
          organizeImports = {
            starThreshold = 9999,
            staticStarThreshold = 9999,
          },
        },
        codeGeneration = {
          toString = {
            template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}",
          },
        },
        project = {
          referencedLibraries = {
            "**/lib/*.jar",
          },
        },
        configuration = {
          runtimes = {
            {
              name = "JavaSE-1.8",
              path = "/usr/lib/jvm/java-8-openjdk-amd64/",
            },
            {
              name = "JavaSE-17",
              path = "/usr/lib/jvm/java-17-openjdk-amd64/",
            },
          },
        },
      },
    },
    flags = {
      allow_incremental_sync = true,
    },
    capabilities = M.capabilities,
    on_attach = on_attach_java,
    on_init = on_init,
    -- stylua: ignore
    cmd = {
      "java",
      "-Declipse.application=org.eclipse.jdt.ls.core.id1",
      "-Dosgi.bundles.defaultStartLevel=4",
      "-Declipse.product=org.eclipse.jdt.ls.core.product",
      "-Dlog.protocol=true",
      "-Dlog.level=ALL",
      "-Xms1G",
      "--add-modules=ALL-SYSTEM",
      "--add-opens", "java.base/java.util=ALL-UNNAMED",
      "--add-opens", "java.base/java.lang=ALL-UNNAMED",
      "-jar", jar,
      "-configuration", config_location,
      "-data", eclipse_wd,
      "-javaagent:" .. lombok,
      -- "-Xbootclasspath/a:" .. lombok,
    },
    root_dir = root_dir,
    init_options = {
      bundles = {
        vim.fn.glob(M.mason_root .. "java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"),
      },
      extendedClientCapabilities = extendedClientCapabilities,
    },
  }

  vim.list_extend(
    config.init_options.bundles,
    vim.split(vim.fn.glob(M.mason_root .. "java-test/extension/server/*.jar"), "\n")
  )

  require("jdtls").start_or_attach(config)
end

local diagnostic_icons = {
  ERROR = "",
  WARN = "",
  HINT = "",
  INFO = "",
}

-- Define the diagnostic signs.
for severity, icon in pairs(diagnostic_icons) do
  local hl = "DiagnosticSign" .. severity:sub(1, 1) .. severity:sub(2):lower()
  vim.fn.sign_define(hl, { text = icon, texthl = hl })
end

vim.diagnostic.config {
  virtual_text = {
    prefix = "",
    ---@param diagnostic Diagnostic
    ---@return string
    format = function(diagnostic)
      local icon = diagnostic_icons[vim.diagnostic.severity[diagnostic.severity]] --[[@as string]]
      local message = vim.split(diagnostic.message, "\n")[1]
      return string.format("%s %s ", icon, message)
    end,
  },
  float = {
    source = "if_many",
    -- Show severity icons as prefixes.
    ---@param diagnostic Diagnostic
    ---@return string, string
    prefix = function(diagnostic)
      local level = vim.diagnostic.severity[diagnostic.severity] --[[@as string]]
      local prefix = string.format(" %s ", diagnostic_icons[level])
      return prefix, "Diagnostic" .. level:gsub("^%l", string.upper)
    end,
  },
  -- Disable signs in the gutter.
  signs = false,
}

-- Override the virtual text diagnostic handler so that the most severe diagnostic is shown first.
local show_handler = vim.diagnostic.handlers.virtual_text.show
local hide_handler = vim.diagnostic.handlers.virtual_text.hide
vim.diagnostic.handlers.virtual_text = {
  show = function(ns, bufnr, diagnostics, opts)
    table.sort(diagnostics, function(diag1, diag2) return diag1.severity > diag2.severity end)
    return show_handler(ns, bufnr, diagnostics, opts)
  end,
  hide = hide_handler,
}

return M
