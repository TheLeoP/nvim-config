local M = {}

local lspconfig = require('lspconfig')
local illuminate = require('illuminate')
local jdtls = require('jdtls')
local jdtls_dap = require('jdtls.dap')
local jdtls_setup = require('jdtls.setup')
local lsp_status = require('lsp-status')
local telescope_builtin = require('telescope.builtin')
local api = vim.api;
local util = vim.lsp.util

lsp_status.register_progress()
lsp_status.config({
    current_function = false,
    show_filename = false,
    indicator_hint = "",
    indicator_ok = "OK"
})

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.resolveSupport = {
  properties = {
    'documentation',
    'detail',
    'additionalTextEdits',
  }
}
capabilities = vim.tbl_extend('keep', capabilities, lsp_status.capabilities)

local on_attach_general = function(client, bufnr)
  illuminate.on_attach(client)
  lsp_status.on_attach(client)

  local opts = {buffer = bufnr}
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
  vim.keymap.set('n', '<c-k>', vim.lsp.buf.signature_help, opts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
  vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, opts)
  vim.keymap.set('n', '<leader>ca', vim.lsp.buf.code_action, opts)
  vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, opts)
  vim.keymap.set('n', '<leader>fds', telescope_builtin.lsp_document_symbols, opts)
  vim.keymap.set('n', '<leader>fws', telescope_builtin.lsp_workspace_symbols, opts)
  vim.keymap.set('n', 'gR', '<cmd>TroubleToggle lsp_references<cr>', opts)
end

local map_formatting = function(client, bufnr)
  local opts = {buffer = bufnr}

  vim.keymap.set('n',
    '<leader>fm',
    function()
      local params = util.make_formatting_params({})
      client.request('textDocument/formatting', params, nil, bufnr)
      vim.lsp.buf.formatting_sync(nil, 1000)
    end,
    opts
  )
end

local on_attach_formatting = function(client, bufnr)
  on_attach_general(client, bufnr)
  map_formatting(client, bufnr)
end

local on_init_general = function(client)
  if client.config.settings then
    client.notify('workspace/didChangeConfiguration', { settings = client.config.settings })
  end
end

-- sobreescribir handlers

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
  vim.lsp.handlers.hover, {
    border = vim.g.lsp_borders
  }
)

-- configuración LS individuales

-- pyright
lspconfig.pyright.setup{
  on_attach = on_attach_general,
  capabilities = capabilities,
}

-- emmet-ls
lspconfig.emmet_ls.setup({
  on_attach = on_attach_general,
  capabilities = capabilities,
})

-- tsserver
lspconfig.tsserver.setup{
  on_attach = on_attach_formatting,
  capabilities = capabilities,
  config = {
    root_dir = jdtls_setup.find_root({'tsconfig.json', 'package.json', 'jsconfig.json', '.git'})
  }
}

local servidores_generales = {
  'vimls',
  'clangd',
  'html',
  'jsonls',
  'cssls',
  'lemminx'
}

for _, server in ipairs(servidores_generales) do
  lspconfig[server].setup(
    {
      on_attach = on_attach_formatting,
      capabilities = capabilities,
    }
  )
end

-- lua
local sumneko_root_path = vim.g.home_dir .. "/.lua-lsp/lua-language-server"
local sumneko_binary
if vim.fn.has('win32') then
  sumneko_binary = vim.g.home_dir .. "/.lua-lsp/lua-language-server/bin/" .. "/lua-language-server"
else
  sumneko_binary = vim.g.home_dir .. "/.lua-lsp/lua-language-server/bin/" .. vim.g.os .. "/lua-language-server"
end
local sumneko_runtime = vim.split(package.path, ';')
table.insert(sumneko_runtime, 'lua/?.lua')
table.insert(sumneko_runtime, 'lua/?/init.lua')
lspconfig.sumneko_lua.setup {
  on_attach = on_attach_general,
  capabilities = capabilities,
  cmd = {sumneko_binary, "-E", sumneko_root_path .. "/main.lua"},
  settings = {
    Lua = {
      runtime = {
        -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
        version = 'LuaJIT',
        runtime = sumneko_runtime,
      },
      diagnostics = {
        -- Get the language server to recognize the `vim` global
        globals = {'vim'}
      },
      workspace = {
        -- Make the server aware of Neovim runtime files
        library = vim.api.nvim_get_runtime_file('', true),
        checkThirdParty = false,
      },
      telemetry = {
        enable = false
      },
    }
  }
}

-- java
local on_attach_java = function(client, bufnr)
  local opts = {
    silent = true
  }

  on_attach_formatting(client, bufnr)
  jdtls.setup_dap({ hotcodereplace = 'auto' })
  jdtls_dap.setup_dap_main_class_configs()
  jdtls_setup.add_commands()
  api.nvim_buf_set_keymap(bufnr, "v", "crv", "<Esc><Cmd>lua require('jdtls').extract_variable(true)<CR>", opts)
  api.nvim_buf_set_keymap(bufnr, "n", "crv", "<Cmd>lua require('jdtls').extract_variable()<CR>", opts)
  api.nvim_buf_set_keymap(bufnr, "v", "crm", "<Esc><Cmd>lua require('jdtls').extract_method(true)<CR>", opts)
end

function M.jdtls_setup()

  local root_dir = jdtls_setup.find_root({'build.gradle', 'pom.xml'})

  -- si no se encuentra la raíz del proyecto, se finaliza sin inicializar jdt.ls
  if not root_dir then
    vim.notify(
      'No se ha encontrado la raíz del proyecto.\nNo se iniciará jdt.ls',
      vim.log.levels.WARN,
      {
        title = 'jdt.ls status',
        timeout = 200
      })
    return
  end

  local antiguo_dir = vim.fn.getcwd();
  if antiguo_dir ~= root_dir then
    vim.api.nvim_set_current_dir(root_dir)
  end

  local eclipse_wd = vim.g.home_dir .. '/java-workspace/' .. vim.fn.fnamemodify(root_dir, ':h:t') .. '/' .. vim.fn.fnamemodify(root_dir, ':t')
  local extendedClientCapabilities = jdtls.extendedClientCapabilities
  extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

  local config = {
    settings = {
      java = {
        signatureHelp = {enabled = true},
        contentProvider = {preferred = 'fernflower'},
        sources = {
          organizeImports = {
            starThreshold = 9999,
            staticStarThreshold = 9999,
          }
        },
        codeGeneration = {
          toString = {
            template = "${object.className}{${member.name()}=${member.value}, ${otherMembers}}"
          }
        }
      },
    },
    flags = {
      allow_incremental_sync = true,
    },
    capabilities = capabilities,
    on_attach = on_attach_java,
    on_init = on_init_general,
    cmd = {
      vim.g.java_lsp_cmd,
      eclipse_wd
    },
    root_dir = root_dir,
    init_options = {
      bundles = {
        vim.fn.glob(vim.g.home_dir .. "/.dap-gadgets/java-debug-0.32.0/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-0.32.0.jar")
      },
      extendedClientCapabilities = extendedClientCapabilities
    }
  }

  jdtls.start_or_attach(config)
end

return M
