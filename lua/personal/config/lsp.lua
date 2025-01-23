local methods = vim.lsp.protocol.Methods

local M = {}

M.mason_root = vim.fn.stdpath "data" .. "/mason/packages/" --[[@as string]]

M.capabilities = vim.lsp.protocol.make_client_capabilities()
M.capabilities.textDocument.completion.completionItem.snippetSupport = true
M.capabilities.textDocument.completion.completionItem.resolveSupport = {
  properties = {
    "documentation",
    "detail",
    "additionalTextEdits",
  },
}
M.capabilities.textDocument.foldingRange = {
  dynamicRegistration = false,
  lineFoldingOnly = true,
}

local lsp_group = vim.api.nvim_create_augroup("LSP", { clear = true })

vim.api.nvim_create_autocmd("LspAttach", {
  group = lsp_group,
  ---@param args {buf:integer, data:{client_id:integer}}}
  callback = function(args)
    local bufnr = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end

    if client.supports_method(methods.textDocument_documentSymbol) then require("nvim-navic").attach(client, bufnr) end

    vim.keymap.set(
      "n",
      "gd",
      function() require("fzf-lua").lsp_definitions { jump_to_single_result = true } end,
      { buffer = bufnr, desc = "Go to definition" }
    )
    vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = bufnr, desc = "Go to declaration" })
    vim.keymap.set(
      "n",
      "gr",
      function() require("fzf-lua").lsp_references { jump_to_single_result = true } end,
      { buffer = bufnr, desc = "Go to reference" }
    )
    vim.keymap.set(
      "n",
      "gi",
      function() require("fzf-lua").lsp_implementations { jump_to_single_result = true } end,
      { buffer = bufnr, desc = "Go to implementation" }
    )
    vim.keymap.set("i", "<c-s>", vim.lsp.buf.signature_help, { buffer = bufnr, desc = "Signature help" })
    vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, { buffer = bufnr, desc = "Rename" })

    vim.keymap.set({ "n", "x" }, "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code actions" })
    vim.keymap.set(
      "n",
      "<leader>fds",
      require("fzf-lua").lsp_document_symbols,
      { buffer = bufnr, desc = "Find document symbols" }
    )
    vim.keymap.set(
      "n",
      "<leader>fws",
      require("fzf-lua").lsp_workspace_symbols,
      { buffer = bufnr, desc = "Find workspace symbols" }
    )
    vim.keymap.set(
      "n",
      "<leader>fki",
      require("fzf-lua").lsp_incoming_calls,
      { buffer = bufnr, desc = "Find incoming calls" }
    )
    vim.keymap.set(
      "n",
      "<leader>fko",
      require("fzf-lua").lsp_outgoing_calls,
      { buffer = bufnr, desc = "Find outgoing calls" }
    )

    -- TODO: registering keymaps in this way may override older kemaps if a new client is attached that does not support inlay hints/codelens
    local inlay_hint = vim.lsp.inlay_hint
    vim.keymap.set("n", "<leader>ti", function()
      if client.supports_method(methods.textDocument_inlayHint) then inlay_hint.enable(not inlay_hint.is_enabled()) end
    end, { buffer = bufnr })

    vim.keymap.set({ "n", "v" }, "<leader>cc", vim.lsp.codelens.run, { desc = "Run codelens" })
    vim.keymap.set("n", "<leader>cC", vim.lsp.codelens.refresh, { desc = "Refresh & display codelens" })

    -- TODO: diabled until https://github.com/neovim/neovim/pull/22115 is merged
    -- vim.api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
    --   buffer = bufnr,
    --   callback = function()
    --     if client.supports_method(methods.textDocument_codeLens) then vim.lsp.codelens.refresh { bufnr = bufnr } end
    --   end,
    -- })
  end,
})

local diagnostic_icons = {
  ERROR = "",
  WARN = "",
  HINT = "",
  INFO = "",
}

-- Define the diagnostic signs.
for severity, icon in pairs(diagnostic_icons) do
  local hl = "DiagnosticSign" .. severity:sub(1, 1) .. severity:sub(2):lower()
  vim.fn.sign_define(hl, { text = icon, texthl = hl })
end

vim.diagnostic.config {
  virtual_text = {
    prefix = "",
    format = function(diagnostic)
      local icon = diagnostic_icons[vim.diagnostic.severity[diagnostic.severity]] --[[@as string]]
      local message = vim.split(diagnostic.message, "\n")[1]
      return string.format("%s %s ", icon, message)
    end,
  },
  float = {
    source = "if_many",
    -- Show severity icons as prefixes.
    prefix = function(diagnostic)
      local level = vim.diagnostic.severity[diagnostic.severity]
      local prefix = string.format(" %s ", diagnostic_icons[level])
      return prefix, "Diagnostic" .. level:gsub("^%l", string.upper)
    end,
  },
  -- Disable signs in the gutter.
  signs = false,
}

-- Override the virtual text diagnostic handler so that the most severe diagnostic is shown first.
local show_handler = vim.diagnostic.handlers.virtual_text.show
---@cast show_handler -nil
local hide_handler = vim.diagnostic.handlers.virtual_text.hide
vim.diagnostic.handlers.virtual_text = {
  show = function(ns, bufnr, diagnostics, opts)
    table.sort(diagnostics, function(diag1, diag2) return diag1.severity > diag2.severity end)
    return show_handler(ns, bufnr, diagnostics, opts)
  end,
  hide = hide_handler,
}

-- TODO: update on 0.11 since vim.lsp.with will be deprecated
vim.lsp.handlers["textDocument/hover"] = vim.lsp.with(vim.lsp.handlers.hover, {
  max_height = math.floor(vim.o.lines * 0.5),
  max_width = math.floor(vim.o.columns * 0.4),
})
vim.lsp.handlers["textDocument/signatureHelp"] = vim.lsp.with(vim.lsp.handlers.signature_help, {
  max_height = math.floor(vim.o.lines * 0.5),
  max_width = math.floor(vim.o.columns * 0.4),
})

return M
