return {
  "neovim/nvim-lspconfig",
  dependencies = {
    "schemastore.nvim",
    "mason-lspconfig.nvim",
    "mason.nvim",
    "blink.cmp",
  },
  config = function()
    local lspconfig = require "lspconfig"
    local capabilities = require("blink.cmp").get_lsp_capabilities(nil, true)

    lspconfig.basedpyright.setup {
      capabilities = capabilities,
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

    -- angular
    lspconfig.angularls.setup {
      capabilities = capabilities,
    }

    -- fennel
    lspconfig.fennel_language_server.setup {
      capabilities = capabilities,
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

    local generic_servers = {
      "vimls",
      "clangd",
      "html",
      "cssls",
      "lemminx",
      "phpactor",
      "prismals",
      -- "cmake",
      "marksman",
      "dockerls",
      "docker_compose_language_service",
    }

    for _, server in ipairs(generic_servers) do
      lspconfig[server].setup {
        capabilities = capabilities,
      }
    end

    -- lua
    lspconfig.lua_ls.setup {
      capabilities = capabilities,
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
            keywordSnippet = "Disable",
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
            librayFiles = "Disabled",
          },
          workspace = {
            checkThirdParty = "Disable",
          },
        },
      },
    }

    -- go
    lspconfig.gopls.setup {
      capabilities = capabilities,
      settings = {
        gopls = {
          gofumpt = true,
        },
      },
    }

    -- json
    lspconfig.jsonls.setup {
      capabilities = capabilities,
      settings = {
        json = {
          schemas = require("schemastore").json.schemas(),
          validate = {
            enable = true,
          },
        },
      },
    }

    -- groovy
    lspconfig.groovyls.setup {
      cmd = { "groovy-language-server" },
      capabilities = capabilities,
      settings = {
        groovy = {
          classpath = vim.list_extend(
            vim.split(vim.fn.glob(vim.env.HOME .. "/.gradle/caches/modules-2/files-2.1/**/*.jar"), "\n"),
            vim.split(vim.fn.glob(vim.env.HOME .. "/.jenkins/**/*.jar"), "\n")
          ),
        },
      },
    }

    -- emmet
    lspconfig.emmet_language_server.setup {
      init_options = {
        showSuggestionsAsSnippets = true,
      },
    }

    -- tailwind
    lspconfig.tailwindcss.setup {
      capabilities = capabilities,
      on_attach = function(client)
        -- disable completion from tailwind because they send too much completion candidates
        client.server_capabilities.completionProvider = nil
      end,
      root_dir = function()
        local root = vim.fs.root(0, {
          "package.json",
        })
        if not root then return end
        local package_json = root .. "/package.json"
        local file = io.open(package_json)
        if not file then return end
        local content = file:read "*a"
        if not content:find [["tailwindcss":]] then return end

        return root
      end,
    }
  end,
}
