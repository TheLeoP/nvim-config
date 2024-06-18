local format_options = {
  autoformat = true,
  excluded_ft = {}, ---@type string[]
}

local slow_format_filetypes = {} ---@type table<string, true>

return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      lua = { "stylua" },
      python = { "black" },
      cs = { "csharpier" },
      javascript = { "prettierd" },
      javascriptreact = { "prettierd" },
      typescript = { "prettierd" },
      typescriptreact = { "prettierd" },
      vue = { "prettierd" },
      css = { "prettierd" },
      scss = { "prettierd" },
      less = { "prettierd" },
      html = { "prettierd" },
      json = { "prettierd" },
      jsonc = { "prettierd" },
      yaml = { "prettierd" },
      markdown = { "prettierd" },
      ["markdown.mdx"] = { "prettierd" },
      graphql = { "prettierd" },
      handlebars = { "prettierd" },
    },
    format_on_save = function(bufnr)
      if not format_options.autoformat then return end

      if slow_format_filetypes[vim.bo[bufnr].filetype] then return end
      local function on_format(err)
        if err and err:match "timeout$" then slow_format_filetypes[vim.bo[bufnr].filetype] = true end
      end

      return {
        timeout_ms = 500,
        lsp_format = vim.list_contains(format_options.excluded_ft, vim.bo[bufnr].filetype) and "never" or "fallback",
      },
        on_format
    end,
    format_after_save = function(bufnr)
      if not format_options.autoformat then return end

      if not slow_format_filetypes[vim.bo[bufnr].filetype] then return end

      return {
        lsp_format = vim.list_contains(format_options.excluded_ft, vim.bo[bufnr].filetype) and "never" or "fallback",
      }
    end,
  },
  config = function(_, opts)
    require("conform").setup(opts)

    vim.keymap.set("n", "<leader>tf", function()
      format_options.autoformat = not format_options.autoformat
      vim.notify(("Autoformat is %s"):format(format_options.autoformat and "on" or "off"))
    end)
  end,
}
