local M = {}

local jdtls = require "jdtls"
local jdtls_dap = require "jdtls.dap"
local jdtls_setup = require "jdtls.setup"
local navic = require "nvim-navic"

M.mason_root = vim.fn.stdpath "data" .. "/mason/packages/"

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

M.on_attach_general = function(client, bufnr)
  if client.server_capabilities.documentSymbolProvider then
    navic.attach(client, bufnr)
  end

  vim.keymap.set("n", "gd", "<cmd>Telescope lsp_definitions<cr>", { buffer = bufnr, desc = "Go to definition" })
  vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = bufnr, desc = "Go to declaration" })
  vim.keymap.set("n", "gr", "<cmd>Telescope lsp_references", { buffer = bufnr, desc = "Go to reference" })
  vim.keymap.set("n", "gi", "<cmd>Telescope lsp_implementations", { buffer = bufnr, desc = "Go to implementation" })
  vim.keymap.set("n", "<c-k>", vim.lsp.buf.signature_help, { buffer = bufnr, desc = "Signature help" })
  vim.keymap.set("n", "K", vim.lsp.buf.hover, { buffer = bufnr, desc = "Hover" })
  vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename" })
  vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code actions" })
  vim.keymap.set(
    "x",
    "<leader>ca",
    ":lua vim.lsp.buf.code_action()<cr>",
    { buffer = bufnr, desc = "Ranged code actions" }
  )
  vim.keymap.set("n", "<leader>e", vim.diagnostic.open_float, { buffer = bufnr, desc = "Show error" })
  vim.keymap.set(
    "n",
    "<leader>fds",
    "<cmd>Telescope lsp_document_symbols",
    { buffer = bufnr, desc = "Find document symbols" }
  )
  vim.keymap.set(
    "n",
    "<leader>fws",
    "<cmd>Telescope lsp_workspace_symbols",
    { buffer = bufnr, desc = "Find workspace symbols" }
  )
  vim.keymap.set(
    "n",
    "<leader>fki",
    "<cmd>Telescope lsp_incoming_calls",
    { buffer = bufnr, desc = "Find incoming calls" }
  )
  vim.keymap.set(
    "n",
    "<leader>fko",
    "<cmd>Telescope lsp_outgoing_calls",
    { buffer = bufnr, desc = "Find outgoing calls" }
  )

  local ft = vim.bo[bufnr].filetype
  local have_null_ls = #require("null-ls.sources").get_available(ft, "NULL_LS_FORMATTING") > 0

  local format = function()
    vim.lsp.buf.format {
      filter = function(client)
        local have_null_ls = #require("null-ls.sources").get_available(ft, "NULL_LS_FORMATTING") > 0
        if have_null_ls then
          return client.name == "null-ls"
        else
          return client.name ~= "null-ls"
        end
      end,
      bufnr = bufnr,
    }
  end
  if client.supports_method "textDocument/formatting" or have_null_ls then
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = vim.api.nvim_create_augroup("LspFormat." .. bufnr, {}),
      buffer = bufnr,
      callback = format,
    })
    vim.keymap.set("n", "<leader>fm", format, { buffer = bufnr, desc = "formatting" })
  end
end

-- java
local on_attach_java = function(client, bufnr)
  M.on_attach_general(client, bufnr)
  jdtls.setup_dap { hotcodereplace = "auto" }
  jdtls_dap.setup_dap_main_class_configs()
  jdtls_setup.add_commands()
end

local on_init = function(client)
  if client.config.settings then
    client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
  end
end

function M.jdtls_setup()
  local root_dir = jdtls_setup.find_root { "build.gradle", "pom.xml", "build.xml" }

  -- si no se encuentra la raíz del proyecto, se finaliza sin inicializar jdt.ls
  if not root_dir then
    vim.notify("No se ha encontrado la raíz del proyecto.\nNo se iniciará jdt.ls", vim.log.levels.WARN, {
      title = "jdt.ls status",
      timeout = 200,
    })
    return
  end

  local eclipse_wd = vim.g.home_dir
    .. "/java-workspace/"
    .. vim.fn.fnamemodify(root_dir, ":h:t")
    .. "/"
    .. vim.fn.fnamemodify(root_dir, ":t")
  local extendedClientCapabilities = jdtls.extendedClientCapabilities
  extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

  local jdtls_root = M.mason_root .. "jdtls/"

  local jar = vim.fn.glob(jdtls_root .. "plugins/org.eclipse.equinox.launcher_*.jar", false, false)
  local config_location = jdtls_root .. (vim.fn.has "win32" == 1 and "config_win" or "config_linux")
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
      },
    },
    flags = {
      allow_incremental_sync = true,
    },
    capabilities = M.capabilities,
    on_attach = on_attach_java,
    on_init = on_init,
    cmd = {
      "java",
      "-Declipse.application=org.eclipse.jdt.ls.core.id1",
      "-Dosgi.bundles.defaultStartLevel=4",
      "-Declipse.product=org.eclipse.jdt.ls.core.product",
      "-Dlog.protocol=true",
      "-Dlog.level=ALL",
      "-Xms1G",
      "--add-modules=ALL-SYSTEM",
      "--add-opens",
      "java.base/java.util=ALL-UNNAMED",
      "--add-opens",
      "java.base/java.lang=ALL-UNNAMED",
      "-jar",
      jar,
      "-configuration",
      config_location,
      "-data",
      eclipse_wd,
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

  jdtls.start_or_attach(config)
end

return M
