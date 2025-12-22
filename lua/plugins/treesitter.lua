local api = vim.api
local iter = vim.iter
local ts = vim.treesitter

return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  config = function()
    ---@type string[]
    local ensure_langs = {
      "bash",
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
      "gitattributes",
      "gitcommit",
      "gitignore",
      "go",
      "gomod",
      "gosum",
      "groovy",
      "html",
      "javascript",
      "typescript",
      "tsx",
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
      "toml",
      "vue",
      "yaml",
      "diff",
      "powershell",
      "astro",
      "desktop",
      "blade",

      "doxygen",
      "re2c",
      "luap",
      "printf",
      "luadoc",
      "jsdoc",
      "regex",
      "angular",
      "scss",
      "phpdoc",
    }
    local already_installed = require("nvim-treesitter").get_installed "parsers"
    local to_install = iter(ensure_langs)
      :filter(function(p)
        return not vim.tbl_contains(already_installed, p)
      end)
      :totable()
    if #to_install > 0 then require("nvim-treesitter").install(to_install) end

    local filetypes = iter(ensure_langs)
      :map(
        ---@param lang string
        function(lang)
          return ts.language.get_filetypes(lang)
        end
      )
      :flatten(1)
      :totable()
    api.nvim_create_autocmd("FileType", {
      pattern = filetypes,
      callback = function(args)
        vim.treesitter.start(args.buf)
      end,
    })
  end,
}
