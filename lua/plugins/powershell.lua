local api = vim.api
local keymap = vim.keymap

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

    local augroup = api.nvim_create_augroup("personal-powershell", { clear = true })
    api.nvim_create_autocmd("User", {
      group = augroup,
      pattern = "powershell.nvim-term",
      callback = function(opts)
        keymap.set("n", "<leader>lt", function()
          require("powershell").toggle_term()
        end, { buffer = opts.data.buf })
      end,
    })
    api.nvim_create_autocmd("User", {
      group = augroup,
      pattern = "powershell.nvim-debug_term",
      callback = function(opts)
        keymap.set("n", "<leader>ld", function()
          require("powershell").toggle_debug_term()
        end, { buffer = opts.data.buf })
      end,
    })
  end,
}
