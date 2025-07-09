local keymap = vim.keymap
local api = vim.api

-- When toggling these, ignore error messages and restore the cursor to the
-- original window when opening the list.
local silent_mods = { mods = { silent = true, emsg_silent = true } }
keymap.set("n", "<leader>tq", function()
  if vim.fn.getqflist({ winid = 0 }).winid ~= 0 then
    vim.cmd.cclose(silent_mods)
  elseif #vim.fn.getqflist() > 0 then
    local win = api.nvim_get_current_win()
    vim.cmd.copen(silent_mods)
    if win ~= api.nvim_get_current_win() then vim.cmd.wincmd "p" end
  end
end, { desc = "Toggle quickfix list" })
keymap.set("n", "<leader>tl", function()
  if vim.fn.getloclist(0, { winid = 0 }).winid ~= 0 then
    vim.cmd.lclose(silent_mods)
  elseif #vim.fn.getloclist(0) > 0 then
    local win = api.nvim_get_current_win()
    vim.cmd.lopen(silent_mods)
    if win ~= api.nvim_get_current_win() then vim.cmd.wincmd "p" end
  end
end, { desc = "Toggle location list" })

keymap.set("n", "<leader>tp", "<cmd>pclose<cr>")

keymap.set("c", "Mes", "mes")

keymap.set({ "n" }, "<leader><leader>t", "<cmd>tab split<cr>")

keymap.set(
  "n",
  "j",
  [[v:count ? "m'" .. v:count .. 'j' : "gj"]],
  { expr = true, desc = "Set qflist if j has a count. Use gj otherwise" }
)
keymap.set(
  "n",
  "k",
  [[v:count ? "m'" .. v:count .. 'k' : "gk"]],
  { expr = true, desc = "Set qflist if k has a count. Use gk otherwise" }
)

-- toggle options

keymap.set("n", "<leader>ts", function()
  vim.wo.spell = not vim.wo.spell
  vim.notify(("Spell is %s for current window"):format(vim.wo.spell and "on" or "off"))
end, { desc = "Toggle spell" })
keymap.set("n", "<leader>tr", function()
  vim.wo.relativenumber = not vim.wo.relativenumber
end, { desc = "Toggle relative numbers" })
keymap.set("n", "<leader>td", function()
  vim.o.background = vim.o.background == "dark" and "light" or "dark"
end, { desc = "Toggle darkmode" })
local last_conceal ---@type integer
keymap.set("n", "<leader>tc", function()
  if vim.bo.filetype == "markdown" then
    vim.cmd.RenderMarkdown "buf_toggle"
    vim.notify "Toggling RenderMarkdown for current buf"
    return
  end

  local current_conceal = vim.wo.conceallevel
  vim.wo.conceallevel = vim.wo.conceallevel ~= 0 and 0 or last_conceal or 3
  vim.notify(("Conceal level is %s"):format(vim.wo.conceallevel))
  last_conceal = current_conceal
end, { desc = "Toggle conceal" })
keymap.set("n", "<leader>tw", function()
  vim.wo.wrap = not vim.wo.wrap
  vim.notify(("Wrap is %s for current window"):format(vim.wo.wrap and "on" or "off"))
end, { desc = "Toggle wrap" })

keymap.set("n", "<leader>tu", "<cmd>UndotreeToggle<cr>")

keymap.set("n", "<c-w>d", function()
  vim.diagnostic.open_float { source = true }
end)

keymap.set("n", "]e", function()
  vim.diagnostic.jump { count = 1, severity = vim.diagnostic.severity.ERROR, float = true }
end, { desc = "Next error" })
keymap.set("n", "[e", function()
  vim.diagnostic.jump { count = -1, severity = vim.diagnostic.severity.ERROR, float = true }
end, { desc = "Prev error" })

-- : operator
keymap.set({ "n", "x" }, "<leader>.", function()
  vim.o.operatorfunc = "v:lua.require'personal.op'.command"
  return "g@"
end, { expr = true })

keymap.set({ "n", "x" }, "<leader>e", function()
  if vim.bo.filetype == "javascript" then return "<cmd>w|!node %<cr>" end

  if vim.bo.filetype ~= "lua" and vim.bo.filetype ~= "vim" then
    vim.schedule(function()
      vim.notify(("Can't source filetype %s"):format(vim.bo.filetype))
    end)
    return "<ignore>"
  end
  return ":source<cr>"
end, { expr = true })

keymap.set("n", "<leader>tn", function()
  vim.diagnostic.config { virtual_lines = not vim.diagnostic.config().virtual_lines }
end, { desc = "Toggle diagnostic virtual_lines" })

keymap.set("x", "g/", "<Esc>/\\%V", { desc = "Search within visual selection" })

for _, motion in ipairs { "F", "T", "b", "B", "ge", "0" } do
  keymap.set("o", motion, "v" .. motion, { desc = ("Backwards inclusive %s"):format(motion) })
end

for _, num in ipairs { 1, 2, 3, 4, 5, 6, 7, 8, 9 } do
  keymap.set("n", ("<leader>%d"):format(num), ("%dgt"):format(num))
  keymap.set("n", ("<leader><leader>%d"):format(num), function()
    local current_tab = vim.fn.tabpagenr()
    if num == 1 then
      vim.cmd.tabmove(("%d"):format(0))
    elseif current_tab < num then
      vim.cmd.tabmove(("%d"):format(num))
    elseif current_tab > num then
      vim.cmd.tabmove(("%d"):format(num - 1))
    end
  end)
end
