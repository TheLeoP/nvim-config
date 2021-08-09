vim.o.completeopt = "menuone,noselect,noinsert"
vim.api.nvim_buf_set_option(0, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
-- compee

require'compe'.setup {
  enabled = true;
  autocomplete = true;
  debug = false;
  min_length = 1;
  preselect = 'enable';
  throttle_time = 80;
  source_timeout = 200;
  incomplete_delay = 400;
  max_abbr_width = 100;
  max_kind_width = 100;
  max_menu_width = 100;
  documentation = true;

  source = {
    path = true;
    buffer = true;
    calc = true;
    ultisnips = false;
    nvim_lsp = true;
    nvim_lua = true;
    spell = false;
    tags = false;
    snippets_nvim = false;
    treesitter = false;
  };
}

--snippets
local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities.textDocument.completion.completionItem.snippetSupport = true
capabilities.textDocument.completion.completionItem.resolveSupport = {
  properties = {
    'documentation',
    'detail',
    'additionalTextEdits',
  }
}

-- on attach
local on_attach = function(client, bufnr)
  require'illuminate'.on_attach(client)
  require'lsp_signature'.on_attach({
      bind = true,
      doc_lines = 0,
      floating_windows = true,
      fix_pos = true,
      hint_enable = false,
      use_lspsaga = false,
      handler_opts = {
        border = { '┏', '━', '┓', '┃', '┛', '━', '┗', '┃' },
      }
    })
end

vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(
  vim.lsp.handlers.signature_help, {
    border = { '┏', '━', '┓', '┃', '┛', '━', '┗', '┃' },
  }
)

vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(
  vim.lsp.handlers.hover, {
    border = { '┏', '━', '┓', '┃', '┛', '━', '┗', '┃' },
  }
)


-- configuración LSP

require'lspconfig'.efm.setup {
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

require'lspconfig'.pyright.setup{
  on_attach = on_attach,
  capabilities = capabilities,
  init_options = {documentFormatting = false, codeAction = true},
}

require'lspconfig'.jsonls.setup {
  on_attach = on_attach,
  capabilities = capabilities,
    commands = {
      Format = {
        function()
          vim.lsp.buf.range_formatting({},{0,0},{vim.fn.line("$"),0})
        end
      }
    }
}

require'lspconfig'.tsserver.setup{
  on_attach = on_attach,
  capabilities = capabilities
}

require'lspconfig'.vimls.setup{
  -- on_attach = on_attach,
  capabilities = capabilities
}

local home
local os
local java_cmd

if vim.fn.has("win32") == 1 then
  home = "C:/Users/pcx/"
  os = "Windows"
  java_cmd = "prueba.bat"
else
  home = "/home/luis/"
  os = "Linux"
  java_cmd = "prueba.sh"
end

local sumneko_root_path = home .. ".lua-lsp/lua-language-server"
local sumneko_binary = home .. ".lua-lsp/lua-language-server/bin/" .. os .. "/lua-language-server"

require'lspconfig'.sumneko_lua.setup {
  on_attach = on_attach,
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
            }
        }
    }
}

require'lspconfig'.clangd.setup {
  on_attach = on_attach,
}

-- devicons
require'nvim-web-devicons'.setup {
 -- your personnal icons can go here (to override)
 -- DevIcon will be appended to `name`
 override = {
  zsh = {
    icon = "",
    color = "#428850",
    name = "Zsh"
  }
 };
 -- globally enable default icons (default to false)
 -- will get overriden by `get_icons` option
 default = true;
}

local M = {}

function M.jdtls_setup()

  local root_dir = require('jdtls.setup').find_root({'build.gradle', 'pom.xml'})

  local antiguo_dir = vim.fn.getcwd();
  if antiguo_dir ~= root_dir then
    vim.api.nvim_set_current_dir(root_dir)
  end

  local eclipse_wd = home .. 'java-workspace/' .. vim.fn.fnamemodify(root_dir, ':h:t') .. '/' .. vim.fn.fnamemodify(root_dir, ':t')

  local config = {
    flags = {
      allow_incremental_sync = true,
    };

    capabilities = capabilities,
    on_attach = on_attach,

    cmd = {
      java_cmd,
      eclipse_wd
    },
    root_dir = root_dir,
    init_options = {
      bundles = {
        vim.fn.glob(home .. "dap-gadgets/java-debug-0.32.0/com.microsoft.java.debug.plugin/target/com.microsoft.java.debug.plugin-0.32.0.jar")
        -- vim.fn.glob(home .. "dap-gadgets/download/vscode-java-debug/0.26.0/root/extension/server/com.microsoft.java.debug.plugin-0.26.0.jar")
      }
    }
  }

  require('jdtls.setup').add_commands()
  require('jdtls').start_or_attach(config)
end

return M
