local lint_options = {
  enabled = true,
}

return {
  "mfussenegger/nvim-lint",
  opts = {},
  config = function()
    require("lint").linters_by_ft = {
      javascript = { "eslint_d" },
      javascriptreact = { "eslint_d" },
      typescript = { "eslint_d" },
      typescriptreact = { "eslint_d" },
      vue = { "eslint_d" },
    }

    vim.api.nvim_create_autocmd({ "BufWritePost" }, {
      group = vim.api.nvim_create_augroup("nvim-lint", { clear = true }),
      callback = function()
        if not lint_options.enabled then return end
        require("lint").try_lint(nil, { ignore_errors = true })
      end,
    })

    vim.keymap.set("n", "<leader>tt", function()
      lint_options.enabled = not lint_options.enabled
      vim.notify(("Linting is %s"):format(lint_options.enabled and "enabled" or "disabled"))
    end)
  end,
}
