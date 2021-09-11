local M = {}

local lspconfig = require('lspconfig')
local illuminate = require('illuminate')
local lsp_signature = require('lsp_signature')
local jdtls = require('jdtls')
local jdtls_dap = require('jdtls.dap')
local jdtls_setup = require('jdtls.setup')
local lsp_status = require('lsp-status')

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

local on_attach_general = function(client, _)
  illuminate.on_attach(client)
  lsp_status.on_attach(client)
  lsp_signature.on_attach({
      bind = true,
      doc_lines = 0,
      floating_windows = true,
      fix_pos = true,
      hint_enable = false,
      use_lspsaga = false,
      handler_opts = {
        border = vim.g.lsp_borders
      }
    })
end

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
  vim.lsp.handlers.signature_help, {
    border = vim.g.lsp_borders
  }
)

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
  vim.lsp.handlers.hover, {
    border = vim.g.lsp_borders
  }
)

-- configuración LS infividuales

-- efm
lspconfig.efm.setup {
    init_options = {documentFormatting = true, codeAction = false},
    filetypes = {'python'},
    settings = {
        rootMarkers = {".git/"},
        languages = {
            python = {
              {
                formatCommand = 'yapf --quiet',
                formatStdin = true
              },
              {
                lintCommand = 'flake8 --ignore=E501 --stdin-display-name ${INPUT} -',
                lintStdin = true,
                lintFormats = {"%f:%l:%c: %m"},
              }
            }
        }
    }
}

-- pyright
lspconfig.pyright.setup{
  on_attach = on_attach_general,
  capabilities = capabilities,
  init_options = {documentFormatting = false, codeAction = true},
}

-- tsserver
lspconfig.tsserver.setup{
  on_attach = on_attach_general,
  capabilities = capabilities
}

-- viml
lspconfig.vimls.setup{
  -- on_attach = on_attach,
  capabilities = capabilities
}


-- lua
local sumneko_root_path = vim.g.home_dir .. "/.lua-lsp/lua-language-server"
local sumneko_binary = vim.g.home_dir .. "/.lua-lsp/lua-language-server/bin/" .. vim.g.os .. "/lua-language-server"
lspconfig.sumneko_lua.setup {
  on_attach = on_attach_general,
  capabilities = capabilities,
    cmd = {sumneko_binary, "-E", sumneko_root_path .. "/main.lua"},
    settings = {
        Lua = {
            runtime = {
                -- Tell the language server which version of Lua you're using (most likely LuaJIT in the case of Neovim)
                version = 'LuaJIT',
                -- Setup your lua path
                path = vim.split(package.path, ';')
            },
            diagnostics = {
                -- Get the language server to recognize the `vim` global
                globals = {'vim'}
            },
            workspace = {
                -- Make the server aware of Neovim runtime files
                library = {[vim.fn.expand('$VIMRUNTIME/lua')] = true, [vim.fn.expand('$VIMRUNTIME/lua/vim/lsp')] = true}
            },
            rootMarkers = {".git/"},
        }
    }
}

-- clangd (C, C++)
lspconfig.clangd.setup {
  on_attach = on_attach_general,
}

-- java
local on_attach_java = function(client, bufnr)
  on_attach_general(client, bufnr)
  jdtls.setup_dap({ hotcodereplace = 'auto' })
  jdtls_dap.setup_dap_main_class_configs()
  jdtls_setup.add_commands()
end

function M.jdtls_setup()

  local root_dir = jdtls_setup.find_root({'build.gradle', 'pom.xml'})

  local antiguo_dir = vim.fn.getcwd();
  if antiguo_dir ~= root_dir then
    vim.api.nvim_set_current_dir(root_dir)
  end

  local eclipse_wd = vim.g.home_dir .. '/java-workspace/' .. vim.fn.fnamemodify(root_dir, ':h:t') .. '/' .. vim.fn.fnamemodify(root_dir, ':t')

  local config = {
    flags = {
      allow_incremental_sync = true,
    },
    capabilities = capabilities,
    on_attach = on_attach_java,
    cmd = {
      vim.g.java_lsp_cmd,
      eclipse_wd
    },
    root_dir = root_dir,
    init_options = {
      bundles = {
        vim.fn.glob(vim.g.home_dir .. "/.dap-gadgets/java-debug-0.32.0/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-0.32.0.jar")
      }
    }
  }

  jdtls.start_or_attach(config)
end

return M
