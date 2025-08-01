local api = vim.api
local iter = vim.iter

return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  config = function()
    ---@type {parser: string, ft: string[]?}[]
    local ts_info = {
      { parser = "bash", ft = { "bash" } },
      { parser = "c", ft = { "c" } },
      { parser = "lua", ft = { "lua" } },
      { parser = "vim", ft = { "vim" } },
      { parser = "xml", ft = { "xml" } },
      { parser = "http", ft = { "http" } },
      { parser = "json", ft = { "json" } },
      { parser = "graphql", ft = { "graphql" } },
      { parser = "query", ft = { "query" } },
      { parser = "vimdoc", ft = { "help" } },
      { parser = "c_sharp", ft = { "cs" } },
      { parser = "cpp", ft = { "cpp" } },
      { parser = "css", ft = { "css" } },
      { parser = "dockerfile", ft = { "dockerfile" } },
      { parser = "editorconfig", ft = { "editorconfig" } },
      { parser = "git_config", ft = { "gitconfig" } },
      { parser = "git_rebase", ft = { "gitrebase" } },
      { parser = "gitattributes", ft = { "gitattributes" } },
      { parser = "gitcommit", ft = { "gitcommit" } },
      { parser = "gitignore", ft = { "gitignore" } },
      { parser = "go", ft = { "go" } },
      { parser = "gomod", ft = { "gomod" } },
      { parser = "gosum", ft = { "gosum" } },
      { parser = "groovy", ft = { "groovy" } },
      { parser = "html", ft = { "html" } },
      { parser = "javascript", ft = { "javascript", "javascriptreact" } },
      { parser = "typescript", ft = { "typescript" } },
      { parser = "tsx", ft = { "typescriptreact" } },
      { parser = "java", ft = { "java" } },
      { parser = "ini", ft = { "ini" } },
      { parser = "jsonc", ft = { "jsonc" } },
      { parser = "make", ft = { "make" } },
      { parser = "markdown", ft = { "markdown" } },
      { parser = "pem", ft = { "pem" } },
      { parser = "php", ft = { "php" } },
      { parser = "proto", ft = { "proto" } },
      { parser = "python", ft = { "python" } },
      { parser = "ruby", ft = { "ruby" } },
      { parser = "sql", ft = { "sql" } },
      { parser = "ssh_config", ft = { "sshconfig" } },
      { parser = "toml", ft = { "toml" } },
      { parser = "vue", ft = { "vue" } },
      { parser = "yaml", ft = { "yaml" } },
      { parser = "diff", ft = { "diff" } },
      { parser = "powershell", ft = { "ps1" } },
      { parser = "astro", ft = { "astro" } },
      { parser = "desktop", ft = { "desktop" } },

      { parser = "doxygen" },
      { parser = "re2c" },
      { parser = "luap" },
      { parser = "printf" },
      { parser = "luadoc" },
      { parser = "jsdoc" },
      { parser = "regex" },
      { parser = "angular" },
      { parser = "scss" },
    }
    local ensure_installed = iter(ts_info)
      :map(function(info)
        return info.parser
      end)
      :totable()
    local already_installed = require("nvim-treesitter.config").get_installed "parsers"
    local to_install = iter(already_installed)
      :filter(function(p)
        return not vim.tbl_contains(already_installed, p)
      end)
      :totable()
    if #to_install > 0 then require("nvim-treesitter").install(ensure_installed) end

    local pattern = iter(ts_info)
      :map(function(info)
        return info.ft
      end)
      :flatten(1)
      :totable()
    api.nvim_create_autocmd("FileType", {
      pattern = pattern,
      callback = function(args)
        vim.treesitter.start(args.buf)
      end,
    })

    api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
      pattern = { "*.component.html", "*.container.html" },
      callback = function(args)
        vim.treesitter.start(args.buf, "angular")
      end,
    })
  end,
}
