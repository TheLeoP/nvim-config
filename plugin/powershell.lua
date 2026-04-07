vim.pack.add { "https://github.com/TheLeoP/powershell.nvim" }

local api = vim.api
local keymap = vim.keymap

local mason_root = vim.fn.stdpath "data" .. "/mason/packages"

require("powershell").setup {
  capabilities = require("blink.cmp").get_lsp_capabilities(nil, true),
  bundle_path = vim.fs.normalize(mason_root .. "/powershell-editor-services"),
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
