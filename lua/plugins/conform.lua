local format_options = {
  autoformat = true,
  excluded_ft = { "xml" }, ---@type string[]
  slow_filetypes = {}, ---@type table<string, true>
}

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
      if not format_options.autoformat or format_options[vim.bo[bufnr].filetype] then return end
      local lsp_fallback = vim.list_contains(format_options.excluded_ft, vim.bo[bufnr].filetype)

      ---@param err string
      local function on_format(err)
        if err and err:match "timeout$" then format_options.slow_filetypes[vim.bo[bufnr].filetype] = true end
      end

      return { timeout_ms = 500, lsp_fallback = lsp_fallback }, on_format
    end,
    format_after_save = function(bufnr)
      if not format_options.autoformat or not format_options.slow_filetypes[vim.bo[bufnr].filetype] then return end
      local lsp_fallback = vim.list_contains(format_options.excluded_ft, vim.bo[bufnr].filetype)
      return { lsp_fallback = lsp_fallback }
    end,
  },
  config = function(_, opts)
    require("conform").setup(opts)

    vim.keymap.set("n", "<leader>tf", function()
      format_options.autoformat = not format_options.autoformat
      vim.notify(string.format("Autoformat is %s", format_options.autoformat and "on" or "off"))
    end)
  end,
}
