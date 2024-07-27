return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "schemastore.nvim",
    "mason-lspconfig.nvim",
    "mason.nvim",
  },
  config = function()
    local lspconfig = require "lspconfig"
    local config = require "personal.config.lsp"

    vim.lsp.handlers["workspace/diagnostic/refresh"] = function(_, _, ctx)
      local ns = vim.lsp.diagnostic.get_namespace(ctx.client_id)
      local bufnr = vim.api.nvim_get_current_buf()
      vim.diagnostic.reset(ns, bufnr)
      return true
    end

    lspconfig.basedpyright.setup {
      capabilities = config.capabilities,
      settings = {
        basedpyright = {
          analysis = {
            typeCheckingMode = "standard",
          },
        },
      },
      root_dir = function()
        return vim.fs.root(0, {
          "setup.cfg",
          "pyproject.toml",
          "setup.cfg",
          "requirements.txt",
          "Pipfile",
          "pyrightconfig.json",
        })
      end,
    }

    -- c#
    lspconfig.omnisharp.setup {
      capabilities = config.capabilities,
      settings = {
        FormattingOptions = {
          OrganizeImports = true,
        },
      },
    }

    -- angular
    lspconfig.angularls.setup {
      capabilities = config.capabilities,
    }

    -- fennel
    lspconfig.fennel_language_server.setup {
      capabilities = config.capabilities,
      settings = {
        fennel = {
          workspace = {
            library = vim.api.nvim_list_runtime_paths(),
          },
          diagnostics = {
            globals = { "vim" },
          },
        },
      },
    }

    -- tailwind
    lspconfig.tailwindcss.setup {
      capabilities = config.capabilities,
      root_dir = function()
        return vim.fs.root(0, {
          "tailwind.config.js",
          "tailwind.config.cjs",
          "tailwind.config.mjs",
          "tailwind.config.ts",
        })
      end,
    }

    local servidores_generales = {
      "vimls",
      "clangd",
      "html",
      "cssls",
      "lemminx",
      "groovyls",
      "phpactor",
      "prismals",
      "cmake",
      "marksman",
      "dockerls",
      "docker_compose_language_service",
    }

    for _, server in ipairs(servidores_generales) do
      lspconfig[server].setup {
        capabilities = config.capabilities,
      }
    end

    -- lua
    lspconfig.lua_ls.setup {
      capabilities = config.capabilities,
      settings = {
        Lua = {
          hint = {
            enable = true,
            arrayIndex = "Disable",
          },
          codelens = {
            enable = true,
          },
          completion = {
            showWord = "Disable",
          },
          diagnostics = {
            groupFileStatus = {
              strict = "Opened",
              strong = "Opened",
            },
            groupSeverity = {
              strict = "Warning",
              strong = "Warning",
            },
            unusedLocalExclude = { "_*" },
          },
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
        ---@type string
        new_config.init_options.typescript.tsdk = config.mason_root
          .. "typescript-language-server/node_modules/typescript/lib"
      end
    end

    lspconfig.volar.setup {
      capabilities = config.capabilities,
      on_new_config = on_new_config,
      filetypes = { "vue" },
    }

    -- go
    lspconfig.gopls.setup {
      capabilities = config.capabilities,
      settings = {
        gopls = {
          gofumpt = true,
        },
      },
    }

    -- json
    lspconfig.jsonls.setup {
      capabilities = config.capabilities,
      settings = {
        json = {
          schemas = require("schemastore").json.schemas(),
          validate = {
            enable = true,
          },
        },
      },
    }
  end,
}
