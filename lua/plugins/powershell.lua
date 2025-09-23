return {
  "TheLeoP/powershell.nvim",
  dev = true,
  config = function()
    require("powershell").setup {
      capabilities = require("blink.cmp").get_lsp_capabilities(nil, true),
      bundle_path = vim.fs.normalize(require("personal.config.lsp").mason_root .. "powershell-editor-services"),
      init_options = {
        enableProfileLoading = false,
      },
      settings = {
        powershell = {
          codeFormatting = {
            openBraceOnSameLine = true,

            useConstantStrings = true,
            useCorrectCasing = true,
            whitespaceAroundOperator = true,
            whitespaceAfterSeparator = true,
            whitespaceBeforeOpenBrace = true,
            addWhitespaceAroundPipe = true,
          },
        },
      },
    }

    local augroup = vim.api.nvim_create_augroup("personal-powershell", { clear = true })
    vim.api.nvim_create_autocmd("User", {
      group = augroup,
      pattern = "powershell.nvim-term",
      callback = function(opts)
        vim.keymap.set("n", "<leader>P", function()
          require("powershell").toggle_term()
        end, { buffer = opts.data.buf })
      end,
    })
  end,
}
