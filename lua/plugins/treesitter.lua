local api = vim.api
local iter = vim.iter

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  config = function()
    local ensure_installed = {
      "c",
      "lua",
      "vim",
      "xml",
      "http",
      "json",
      "graphql",
      "query",
      "vimdoc",
      "c_sharp",
      "cpp",
      "css",
      "dockerfile",
      "editorconfig",
      "git_config",
      "git_rebase",
      "go",
      "gomod",
      "gosum",
      "gitattributes",
      "gitcommit",
      "gitignore",
      "groovy",
      "html",
      "javascript",
      "java",
      "ini",
      "jsonc",
      "make",
      "markdown",
      "pem",
      "php",
      "proto",
      "python",
      "ruby",
      "sql",
      "ssh_config",
      "tsx",
      "toml",
      "typescript",
      "vue",
      "yaml",
      "diff",

      "doxygen",
      "re2c",
      "luap",
      "printf",
      "luadoc",
      "jsdoc",
      "regex",

      "angular",
      "scss",

      "powershell",

      "astro",
    }
    local already_installed = require("nvim-treesitter.config").get_installed "parsers"
    local to_install = iter(already_installed)
      :filter(function(p)
        return not vim.tbl_contains(already_installed, p)
      end)
      :totable()
    if #to_install > 0 then require("nvim-treesitter").install(ensure_installed) end

    api.nvim_create_autocmd("FileType", {
      -- TODO: join both tables with some kind of relationship between them
      pattern = {
        "c",
        "lua",
        "javascript",
        "javascriptreact",
        "typescript",
        "typescriptreact",
        "json",
        "http",
        "xml",
        "vim",
        "query",
        "help",

        "go",
        "gomod",
        "gosum",
        "bash",
        "cs",
        "cpp",
        "css",
        "desktop",
        "diff",
        "dockerfile",
        "editorconfig",
        "gitconfig",
        "gitrebase",
        "gitattributes",
        "gitcommit",
        "gitignore",
        "groovy",
        "html",
        "java",
        "ini",
        "jsonc",
        "make",
        "markdown",
        "pem",
        "php",
        "proto",
        "python",
        "ruby",
        "sql",
        "sshconfig",
        "tsx",
        "toml",
        "vue",

        "yaml",

        "ps1",

        "astro",
      },
      callback = function()
        vim.treesitter.start()
      end,
    })

    api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
      pattern = { "*.component.html", "*.container.html" },
      callback = function()
        vim.treesitter.start(nil, "angular")
      end,
    })
  end,
}
