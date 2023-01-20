local M = {}

local lspconfig = require "lspconfig"
local jdtls = require "jdtls"
local jdtls_dap = require "jdtls.dap"
local jdtls_setup = require "jdtls.setup"
local telescope_builtin = require "telescope.builtin"
local navic = require "nvim-navic"

local api = vim.api

local mason_root = vim.fn.stdpath "data" .. "/mason/packages/"

require("mason").setup()
require("mason-lspconfig").setup {
  ensure_installed = { "tsserver", "volar", "jdtls" },
  automatic_installation = true,
}

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.resolveSupport = {
  properties = {
    "documentation",
    "detail",
    "additionalTextEdits",
  },
}
capabilities.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true,
}

local on_attach_general = function(client, bufnr)
  if client.server_capabilities.documentSymbolProvider then
    navic.attach(client, bufnr)
  end

  vim.keymap.set("n", "gd", telescope_builtin.lsp_definitions, { buffer = bufnr, desc = "Go to definition" })
  vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = bufnr, desc = "Go to declaration" })
  vim.keymap.set("n", "gr", telescope_builtin.lsp_references, { buffer = bufnr, desc = "Go to reference" })
  vim.keymap.set("n", "gi", telescope_builtin.lsp_implementations, { buffer = bufnr, desc = "Go to implementation" })
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
    telescope_builtin.lsp_document_symbols,
    { buffer = bufnr, desc = "Find document symbols" }
  )
  vim.keymap.set(
    "n",
    "<leader>fws",
    telescope_builtin.lsp_workspace_symbols,
    { buffer = bufnr, desc = "Find workspace symbols" }
  )
  vim.keymap.set(
    "n",
    "<leader>fki",
    telescope_builtin.lsp_incoming_calls,
    { buffer = bufnr, desc = "Find incoming calls" }
  )
  vim.keymap.set(
    "n",
    "<leader>fko",
    telescope_builtin.lsp_outgoing_calls,
    { buffer = bufnr, desc = "Find outgoing calls" }
  )

  local format = function()
    local ft = vim.bo[bufnr].filetype
    local have_null_ls = #require("null-ls.sources").get_available(ft, "NULL_LS_FORMATTING") > 0
    vim.lsp.buf.format {
      filter = function(client)
        if have_null_ls then
          return client.name == "null-ls"
        else
          return client.name ~= "null-ls"
        end
      end,
      bufnr = bufnr,
    }
  end
  if client.supports_method "textDocument/formatting" then
    vim.api.nvim_create_autocmd("BufWritePre", {
      group = vim.api.nvim_create_augroup("LspFormat." .. bufnr, {}),
      buffer = bufnr,
      callback = format,
    })
    vim.keymap.set("n", "<leader>fm", format, { buffer = bufnr, desc = "" })
  end
end

local on_init_general = function(client)
  if client.config.settings then
    client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
  end
end

-- sobreescribir handlers

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  border = vim.g.lsp_borders,
})

vim.lsp.handlers["workspace/diagnostic/refresh"] = function(_, _, ctx)
  local ns = vim.lsp.diagnostic.get_namespace(ctx.client_id)
  local bufnr = vim.api.nvim_get_current_buf()
  vim.diagnostic.reset(ns, bufnr)
  return true
end

-- configuración LS individuales

-- pyright
lspconfig.pyright.setup {
  on_attach = on_attach_general,
  capabilities = capabilities,
}

-- emmet
lspconfig.emmet_ls.setup {
  capabilities = capabilities,
  filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue", "php", "html" },
}

require("typescript").setup {
  server = {
    on_attach = on_attach_general,
    capabilities = capabilities,
    root_dir = function()
      return jdtls_setup.find_root { ".git" }
    end,
  },
}

local null_ls = require "null-ls"
null_ls.setup {
  on_attach = on_attach_general,
  sources = {
    -- null_ls.builtins.diagnostics.eslint_d,
    -- null_ls.builtins.code_actions.eslint_d,
    null_ls.builtins.code_actions.refactoring,
    null_ls.builtins.formatting.prettierd,
    null_ls.builtins.formatting.stylua,
    null_ls.builtins.formatting.black,
  },
}

local servidores_generales = {
  "vimls",
  "clangd",
  "html",
  "jsonls",
  "cssls",
  "lemminx",
  "intelephense",
}

for _, server in ipairs(servidores_generales) do
  lspconfig[server].setup {
    on_attach = on_attach_general,
    capabilities = capabilities,
  }
end

-- lua

require("neodev").setup {}
lspconfig.sumneko_lua.setup {
  on_attach = on_attach_general,
  capabilities = capabilities,
  settings = {
    Lua = {
      workspace = {
        checkThirdParty = false,
      },
    },
  },
}

-- vue

local function on_new_config(new_config, _)
  if
    new_config.init_options
    and new_config.init_options.typescript
    and new_config.init_options.typescript.tsdk == ""
  then
    new_config.init_options.typescript.tsdk = mason_root .. "typescript-language-server/node_modules/typescript/lib"
  end
end

lspconfig.volar.setup {
  on_attach = on_attach_general,
  capabilities = capabilities,
  on_new_config = on_new_config,
  filetypes = { "vue" },
}

-- go
lspconfig.gopls.setup {
  on_attach = on_attach_general,
  capabilities = capabilities,
  settings = {
    gopls = {
      gofumpt = true,
    },
  },
}

-- powershell
lspconfig.powershell_es.setup {
  on_attach = on_attach_general,
  capabilities = capabilities,
  bundle_path = mason_root .. "powershell-editor-services",
}

-- java
local on_attach_java = function(client, bufnr)
  local opts = {
    silent = true,
  }

  on_attach_general(client, bufnr)
  jdtls.setup_dap { hotcodereplace = "auto" }
  jdtls_dap.setup_dap_main_class_configs()
  jdtls_setup.add_commands()
  api.nvim_buf_set_keymap(bufnr, "v", "crv", "<Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>", opts)
  api.nvim_buf_set_keymap(bufnr, "n", "crv", "<Cmd>lua require('jdtls').extract_variable()<CR>", opts)
  api.nvim_buf_set_keymap(bufnr, "v", "crm", "<Esc><Cmd>lua require('jdtls').extract_method(true)<CR>", opts)
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

  local jdtls_root = mason_root .. "jdtls/"

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
    capabilities = capabilities,
    on_attach = on_attach_java,
    on_init = on_init_general,
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
        vim.fn.glob(mason_root .. "java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"),
      },
      extendedClientCapabilities = extendedClientCapabilities,
    },
  }

  vim.list_extend(
    config.init_options.bundles,
    vim.split(vim.fn.glob(mason_root .. "java-test/extension/server/*.jar"), "\n")
  )

  jdtls.start_or_attach(config)
end

return M
