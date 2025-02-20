local format_options = require("personal.format").format_options

local slow_format_filetypes = {} ---@type table<string, true>

return {
  "stevearc/conform.nvim",
  ---@type conform.setupOpts
  opts = {
    formatters_by_ft = {
      ["markdown.mdx"] = { "prettierd" },
      cs = { "csharpier" },
      css = { "prettierd" },
      graphql = { "prettierd" },
      handlebars = { "prettierd" },
      html = { "prettierd" },
      javascript = { "prettierd" },
      javascriptreact = { "prettierd" },
      json = { "jq" },
      jsonc = { "prettierd" },
      less = { "prettierd" },
      lua = { "stylua" },
      markdown = { "prettierd" },
      psql = { "sql_formatter" },
      python = { "black" },
      scss = { "prettierd" },
      sql = { "sql_formatter" },
      typescript = { "prettierd" },
      typescriptreact = { "prettierd" },
      vue = { "prettierd" },
      yaml = { "prettierd" },
    },
    format_on_save = function(bufnr)
      if not format_options.autoformat then return end
      if vim.list_contains(format_options.excluded_ft, vim.bo[bufnr].filetype) then return end

      if slow_format_filetypes[vim.bo[bufnr].filetype] then return end
      local function on_format(err)
        if err and err:match "timeout$" then slow_format_filetypes[vim.bo[bufnr].filetype] = true end
      end

      return {
        timeout_ms = 500,
        lsp_format = vim.list_contains(format_options.excluded_lsp_ft, vim.bo[bufnr].filetype) and "never"
          or "fallback",
      },
        on_format
    end,
    format_after_save = function(bufnr)
      if not format_options.autoformat then return end
      if vim.list_contains(format_options.excluded_ft, vim.bo[bufnr].filetype) then return end

      if not slow_format_filetypes[vim.bo[bufnr].filetype] then return end

      return {
        lsp_format = vim.list_contains(format_options.excluded_lsp_ft, vim.bo[bufnr].filetype) and "never"
          or "fallback",
      }
    end,
  },
  config = function(_, opts)
    require("conform").setup(opts)
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"

    vim.keymap.set("n", "<leader>tf", function()
      format_options.autoformat = not format_options.autoformat
      vim.notify(("Autoformat is %s"):format(format_options.autoformat and "on" or "off"))
    end, { desc = "Toggle autoformat" })
  end,
}
