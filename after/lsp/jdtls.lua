local lsp = require "personal.config.lsp"

local bundles = {
  vim.fn.glob(lsp.mason_root .. "java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar", true),
}
vim.list_extend(bundles, vim.split(vim.fn.glob(lsp.mason_root .. "java-test/extension/server/*.jar", true), "\n"))

---@type vim.lsp.Config
return {
  cmd = function(dispatchers, config)
    local jdtls_root = lsp.mason_root .. "jdtls"
    local jar = vim.fn.glob(jdtls_root .. "/plugins/org.eclipse.equinox.launcher_*.jar", false, false)
    local config_location = jdtls_root .. (vim.fn.has "win32" == 1 and "/config_win" or "/config_linux")

    local eclipse_wd = table.concat {
      vim.fn.stdpath "cache",
      "/java-workspace/",
      vim.fn.fnamemodify(config.root_dir, ":h:t"),
      "/",
      vim.fn.fnamemodify(config.root_dir, ":t"),
    }

    return vim.lsp.rpc.start({
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
    }, dispatchers)
  end,
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
            path = "/usr/lib/jvm/java-8-openjdk/",
          },
          {
            name = "JavaSE-17",
            path = "/usr/lib/jvm/java-17-openjdk/",
          },
          {
            name = "JavaSE-21",
            path = "/usr/lib/jvm/java-21-openjdk/",
          },
        },
      },
    },
  },
  init_options = {
    bundles = bundles,
  },
}
