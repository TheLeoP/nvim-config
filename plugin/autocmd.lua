local uv = vim.uv

vim.api.nvim_create_autocmd("TextYankPost", {
  group = vim.api.nvim_create_augroup("HighlightOnYank", { clear = true }),
  desc = "Highlights yanked area",
  callback = function()
    -- Setting a priority higher than the LSP references one.
    vim.highlight.on_yank { higroup = "Visual", priority = 4200 }
  end,
})

vim.api.nvim_create_autocmd("CmdwinEnter", {
  group = vim.api.nvim_create_augroup("ExecuteCmdAndStay", { clear = true }),
  desc = "Execute command and stay in the command-line window",
  callback = function(args)
    vim.keymap.set({ "n", "i" }, "<S-CR>", "<cr>q:", { buffer = args.buf })
  end,
})

vim.api.nvim_create_autocmd("Filetype", {
  group = vim.api.nvim_create_augroup("Format options", { clear = true }),
  desc = "Remove unwanted flags from format options",
  callback = function()
    vim.o.formatoptions = "qjl1rn"
  end,
})

vim.api.nvim_create_autocmd("TermOpen", {
  group = vim.api.nvim_create_augroup("Terminal", { clear = true }),
  desc = "Terminal related settings",
  callback = function(args)
    -- NOTE: disable fold inside terminal https://github.com/neovim/neovim/issues/20726
    vim.opt_local.foldmethod = "manual"
    vim.opt_local.foldenable = false

    vim.opt_local.sidescrolloff = 0

    vim.keymap.set("t", "<esc>", "<c-\\><c-n>", { buffer = args.buf })
  end,
})

vim.api.nvim_create_autocmd("BufNewFile", {
  group = vim.api.nvim_create_augroup("templates", { clear = true }),
  desc = "Load template file",
  callback = function(args)
    local luasnip = require "luasnip"

    local config = vim.fn.stdpath "config"

    local fname = vim.fn.fnamemodify(args.file, ":t")
    local ext = vim.fn.fnamemodify(args.file, ":e")
    local candidates = { fname, ext }
    for _, candidate in ipairs(candidates) do
      local tpl = table.concat { config, "/templates/", candidate, ".tpl" }
      if not uv.fs_stat(tpl) then goto continue end

      vim.cmd.read { range = { 0 }, args = { tpl } }
      do
        return
      end

      ::continue::
    end
    for _, candidate in ipairs(candidates) do
      local stpl = table.concat { config, "/templates/", candidate, ".stpl" }
      local f = io.open(stpl, "r")
      if not f then goto continue end

      local content = f:read "*a"
      luasnip.lsp_expand(content)
      do
        return
      end

      ::continue::
    end
  end,
})

-- show cursor line only in active window
local cursorline_augroup = vim.api.nvim_create_augroup("cursorline-active-window", { clear = true })
vim.api.nvim_create_autocmd("WinEnter", {
  group = cursorline_augroup,
  callback = function()
    local win = vim.api.nvim_get_current_win()
    -- Schedule to preserve the correct order of events when synchronously
    -- changing between windows a bunch of times (like in `<c-w>t`)
    vim.schedule(function()
      if not vim.api.nvim_win_is_valid(win) then return end
      if not vim.w[win].cached_cursorline then return end

      vim.wo[win].cursorline = vim.w[win].cached_cursorline
      vim.w[win].cached_cursorline = nil
    end)
  end,
})
vim.api.nvim_create_autocmd("WinLeave", {
  group = cursorline_augroup,
  callback = function()
    local win = vim.api.nvim_get_current_win()
    -- Copying the current window options seems to be done after `WinLeave`
    -- when opening a new tab. Delay setting `cursorline` to `false` until
    -- after the options are copied
    vim.schedule(function()
      if not vim.api.nvim_win_is_valid(win) then return end
      vim.w[win].cached_cursorline = vim.wo[win].cursorline
      vim.wo[win].cursorline = false
    end)
  end,
})
