local methods = vim.lsp.protocol.Methods
local api = vim.api
local keymap = vim.keymap

local diagnostic_icons = require("personal.icons").diagnostic

local M = {}

M.mason_root = vim.fn.stdpath "data" .. "/mason/packages/" --[[@as string]]

local lsp_group = api.nvim_create_augroup("LSP", { clear = true })

---@param client vim.lsp.Client
---@param buf integer
local function on_attach(client, buf)
  if client:supports_method(methods.textDocument_documentSymbol) then require("nvim-navic").attach(client, buf) end

  if client:supports_method(methods.textDocument_hover) then
    keymap.set("n", "K", function()
      vim.lsp.buf.hover {
        max_height = math.floor(vim.o.lines * 0.5),
        max_width = math.floor(vim.o.columns * 0.4),
      }
    end, { buffer = buf, desc = "Hover" })
  end
  if client:supports_method(methods.textDocument_definition) then
    keymap.set("n", "gd", function()
      require("fzf-lua").lsp_definitions { jump1 = true }
    end, { buffer = buf, desc = "Go to definition" })
  end
  keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = buf, desc = "Go to declaration" })
  keymap.set("n", "grr", function()
    require("fzf-lua").lsp_references { jump1 = true }
  end, { buffer = buf, desc = "Go to reference" })
  keymap.set("n", "grt", function()
    require("fzf-lua").lsp_typedefs { jump1 = true }
  end, { buffer = buf, desc = "Go to reference" })
  keymap.set("n", "gri", function()
    require("fzf-lua").lsp_implementations { jump1 = true }
  end, { buffer = buf, desc = "Go to implementation" })
  if client:supports_method(methods.textDocument_signatureHelp) then
    keymap.set("i", "<c-s>", function()
      -- TODO: remove if I ever change from blink.cmp. Maybe move this into its plugin spec?
      local cmp = require "blink.cmp"
      if cmp.is_menu_visible() then cmp.hide() end
      vim.lsp.buf.signature_help {
        max_height = math.floor(vim.o.lines * 0.5),
        max_width = math.floor(vim.o.columns * 0.4),
      }
    end, { buffer = buf, desc = "Signature help" })
  end

  keymap.set("n", "gO", require("fzf-lua").lsp_document_symbols, { buffer = buf, desc = "Find document symbols" })
  keymap.set(
    "n",
    "<leader>fws",
    require("fzf-lua").lsp_workspace_symbols,
    { buffer = buf, desc = "Find workspace symbols" }
  )
  keymap.set("n", "<leader>fki", require("fzf-lua").lsp_incoming_calls, { buffer = buf, desc = "Find incoming calls" })
  keymap.set("n", "<leader>fko", require("fzf-lua").lsp_outgoing_calls, { buffer = buf, desc = "Find outgoing calls" })

  if client:supports_method(methods.textDocument_inlayHint) then
    local inlay_hint = vim.lsp.inlay_hint
    keymap.set("n", "<leader>ti", function()
      inlay_hint.enable(not inlay_hint.is_enabled())
    end, { buffer = buf, desc = "Toggle inlay hints" })
  end

  keymap.set({ "n", "x" }, "<leader>cc", vim.lsp.codelens.run, { desc = "Run codelens" })
  keymap.set("n", "<leader>cC", vim.lsp.codelens.refresh, { desc = "Refresh & display codelens" })

  -- TODO: disabled until https://github.com/neovim/neovim/pull/22115 is merged
  -- api.nvim_create_autocmd({ "BufEnter", "CursorHold", "InsertLeave" }, {
  --   buffer = bufnr,
  --   callback = function()
  --     if client.supports_method(methods.textDocument_codeLens) then vim.lsp.codelens.refresh { bufnr = bufnr } end
  --   end,
  -- })
end

api.nvim_create_autocmd("LspAttach", {
  group = lsp_group,
  ---@param args {buf:integer, data:{client_id:integer}}
  callback = function(args)
    local buf = args.buf
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if not client then return end

    on_attach(client, buf)
  end,
})

vim.lsp.config("*", { workspace_required = true })

-- Update mappings when registering dynamic capabilities.
local overriden = vim.lsp.handlers[methods.client_registerCapability]
vim.lsp.handlers[methods.client_registerCapability] = function(err, res, ctx)
  local return_value = overriden(err, res, ctx)

  local client = vim.lsp.get_client_by_id(ctx.client_id)
  if not client then return return_value end

  for buf in pairs(client.attached_buffers) do
    on_attach(client, buf)
  end

  return return_value
end

vim.diagnostic.config {
  virtual_text = {
    prefix = "",
    format = function(diagnostic)
      local icon = diagnostic_icons[vim.diagnostic.severity[diagnostic.severity]] --[[@as string]]
      local message = vim.split(diagnostic.message, "\n")[1]
      return ("%s %s "):format(icon, message)
    end,
  },
  float = {
    source = "if_many",
    -- Show severity icons as prefixes.
    prefix = function(diagnostic)
      local level = vim.diagnostic.severity[diagnostic.severity]
      local prefix = (" %s "):format(diagnostic_icons[level])
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
    table.sort(diagnostics, function(diag1, diag2)
      return diag1.severity > diag2.severity
    end)
    return show_handler(ns, bufnr, diagnostics, opts)
  end,
  hide = hide_handler,
}

return M
