return {
  "mfussenegger/nvim-jdtls",
  dependencies = { "blink.cmp" },
  config = function()
    local lsp = require "personal.config.lsp"

    local function attach_jdtls()
      local jdtls_setup = require "jdtls.setup"
      local root_dir = jdtls_setup.find_root { "build.gradle", "pom.xml", "build.xml" }

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

      local jdtls_root = lsp.mason_root .. "jdtls/"

      local jar = vim.fn.glob(jdtls_root .. "plugins/org.eclipse.equinox.launcher_*.jar", false, false)
      local config_location = jdtls_root .. (vim.fn.has "win32" == 1 and "config_win" or "config_linux")
      local lombok = lsp.mason_root .. "jdtls/lombok.jar"
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
        capabilities = require("blink.cmp").get_lsp_capabilities(nil, true),
        on_attach = function()
          require("jdtls").setup_dap { hotcodereplace = "auto", config_overrides = {} }
          require("jdtls.dap").setup_dap_main_class_configs()
        end,
        on_init = function(client)
          if client.config.settings then
            client.notify("workspace/didChangeConfiguration", { settings = client.config.settings })
          end
        end,
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
            vim.fn.glob(lsp.mason_root .. "java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar"),
          },
          extendedClientCapabilities = extendedClientCapabilities,
        },
      }

      vim.list_extend(
        config.init_options.bundles,
        vim.split(vim.fn.glob(lsp.mason_root .. "java-test/extension/server/*.jar"), "\n")
      )

      require("jdtls").start_or_attach(config)
    end

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "java",
      callback = attach_jdtls,
    })
  end,
}
