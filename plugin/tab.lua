local api = vim.api

function _G._personal_tab()
  local last = vim.fn.tabpagenr "$"
  local current = vim.fn.tabpagenr()

  local out = {} ---@type string[]
  for i = 1, last do
    table.insert(out, i == current and "%#TabLineSel#" or "%#TabLine#")
    table.insert(out, ("%%%dT"):format(i)) -- set the tab page number (for mouse clicks)

    table.insert(out, (" %d| %%{v:lua._personal_tab_label(%d)} "):format(i, i))
  end
  table.insert(out, "%#TabLineFill#%T")
  table.insert(out, "%=%#TabLine#%999XX")

  return table.concat(out)
end

---@param i integer
function _G._personal_tab_label(i)
  local buflist = vim.fn.tabpagebuflist(i) ---@type integer[]
  local winnr = vim.fn.tabpagewinnr(i)
  local buf = buflist[winnr]
  local name = api.nvim_buf_get_name(buf)
  local protocol = name:match "^(.*)://"
  if name == "" then
    return "[No name]"
  elseif protocol == "fugitive" or protocol == "health" then
    return protocol .. "://"
  elseif vim.endswith(name, "/") or vim.endswith(name, "\\") then
    local dirname = name:sub(1, -2)
    local tail = vim.fn.fnamemodify(dirname, ":t")
    return tail .. "/"
  end
  local tail = vim.fn.fnamemodify(name, ":t")
  return tail
end

vim.o.tabline = "%{%v:lua._personal_tab()%}"
