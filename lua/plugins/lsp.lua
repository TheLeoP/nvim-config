return {
  -- lsp
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "b0o/schemastore.nvim",
      {
        "williamboman/mason.nvim",
        build = ":MasonUpdate",
      },
      "williamboman/mason-lspconfig.nvim",
      "folke/neodev.nvim",
      "mfussenegger/nvim-jdtls",
      {
        "pmizio/typescript-tools.nvim",
        dependencies = { "nvim-lua/plenary.nvim", "neovim/nvim-lspconfig" },
      },
    },
    config = function()
      local lspconfig = require "lspconfig"
      local jdtls_setup = require "jdtls.setup"
      local config = require "personal.config.lsp"

      require("mason").setup()
      require("mason-lspconfig").setup {
        ensure_installed = { "jdtls" },
        automatic_installation = true,
      }

      vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
        border = vim.g.lsp_borders,
      })

      vim.lsp.handlers["workspace/diagnostic/refresh"] = function(_, _, ctx)
        local ns = vim.lsp.diagnostic.get_namespace(ctx.client_id)
        local bufnr = vim.api.nvim_get_current_buf()
        vim.diagnostic.reset(ns, bufnr)
        return true
      end

      -- emmet
      lspconfig.emmet_ls.setup {
        capabilities = config.capabilities,
        filetypes = { "typescript", "javascript", "javascriptreact", "typescriptreact", "vue", "php", "html" },
      }

      require("typescript-tools").setup {
        capabilities = config.capabilities,
        root_dir = function() return jdtls_setup.find_root { ".git" } end,
        settings = {
          expose_as_code_action = {
            "add_missing_imports",
            "remove_unused_imports",
            "organize_imports",
          },
        },
      }
      lspconfig.pyright.setup {
        capabilities = config.capabilities,
        settings = {
          python = {
            analysis = {
              autoSearchPaths = true,
              diagnosticMode = "workspace",
              useLibraryCodeForTypes = true,
              diagnosticSeverityOverrides = {
                reportGeneralTypeIssues = "warning",
              },
            },
          },
        },
        root_dir = function()
          return jdtls_setup.find_root {
            "setup.cfg",
            "pyproject.toml",
            "setup.cfg",
            "requirements.txt",
            "Pipfile",
            "pyrightconfig.json",
          }
        end,
      }

      -- c#
      require("lspconfig").omnisharp.setup {
        capabilities = config.capabilities,
      }

      -- angular
      require("lspconfig").angularls.setup {
        capabilities = config.capabilities,
      }

      -- fennel
      require("lspconfig").fennel_language_server.setup {
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

      local servidores_generales = {
        "vimls",
        "clangd",
        "html",
        "cssls",
        "lemminx",
        -- "groovyls",
        "intelephense",
        "prismals",
        "eslint",
      }

      for _, server in ipairs(servidores_generales) do
        lspconfig[server].setup {
          capabilities = config.capabilities,
        }
      end

      -- lua

      require("neodev").setup()
      lspconfig.lua_ls.setup {
        capabilities = config.capabilities,
        settings = {
          Lua = {
            hint = {
              enable = true,
              arrayIndex = "Disable",
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
  },
  {
    "nvimtools/none-ls.nvim",
    opts = function()
      local nls = require "null-ls"
      return {
        sources = {
          nls.builtins.formatting.prettierd,
          nls.builtins.formatting.stylua,
          nls.builtins.formatting.black.with { extra_args = { "--line-length=80", "--skip-string-normalization" } },
        },
      }
    end,
  },
  {
    "jay-babu/mason-null-ls.nvim",
    opts = {
      automatic_installation = true,
    },
    dependencies = {
      "nvimtools/none-ls.nvim",
      "williamboman/mason.nvim",
    },
  },
  {
    "j-hui/fidget.nvim",
    opts = {
      progress = {
        ignore = { "null-ls" },
      },
    },
  },
  {
    "SmiteshP/nvim-navic",
    opts = {},
    dependencies = {
      "neovim/nvim-lspconfig",
    },
  },
  {
    "RRethy/vim-illuminate",
    dependencies = {
      "neovim/nvim-lspconfig",
    },
  },
  {
    "TheLeoP/powershell.nvim",
    dev = true,
    ---@type powershell.config
    opts = {
      capabilities = require("personal.config.lsp").capabilities,
      bundle_path = vim.fs.normalize(require("personal.config.lsp").mason_root .. "powershell-editor-services"),
      init_options = {
        enableProfileLoading = false,
      },
      settings = {
        enableProfileLoading = false,
      },
    },
  },
}
