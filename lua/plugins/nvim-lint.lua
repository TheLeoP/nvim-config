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
      callback = function()
        if not lint_options.enabled then return end
        require("lint").try_lint()
      end,
    })

    vim.keymap.set("n", "<leader>tl", function()
      lint_options.enabled = not lint_options.enabled
      vim.notify(("Linting is %s"):format(lint_options.enabled and "enabled" or "disabled"))
    end)
  end,
}
