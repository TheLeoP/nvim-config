require("personal.util.writing").setup()

-- Permite crear un *operador* usando el nombre de una función lua.
-- El nombre de la función puede incluir 'require', pero se deben omitir los paréntesis
-- Ejemplo:
--
-- ```lua
-- operatorfunc_lua("require'foo.bar'.something")
-- ```
---@param fn_name string nombre de la función que será el *operador*
---@return function @closure a usar como parámetro en vim.keymap.set
local operatorfunc_lua = function(fn_name)
  return function()
    vim.o.operatorfunc = ("v:lua.%s"):format(fn_name)
    return "g@"
  end
end

vim.keymap.set(
  "n",
  "<leader>b",
  operatorfunc_lua "require'personal.util.markdown'.bold",
  { buffer = true, expr = true }
)

vim.keymap.set(
  "n",
  "<leader>i",
  operatorfunc_lua "require'personal.util.markdown'.italic",
  { buffer = true, expr = true }
)

-- <c-bs>
vim.keymap.set("n", "\08", function()
  local cur_line = vim.api.nvim_get_current_line()
  local replacement ---@type string
  if cur_line:match "^%s*- %[ %]" then
    replacement = cur_line:gsub("%[ %]", "[x]")
  else
    replacement = cur_line:gsub("%[x%]", "[ ]")
  end
  vim.api.nvim_set_current_line(replacement)
end, { buffer = true })
vim.keymap.set("n", "<c-cr>", function()
  local row, col = unpack(vim.api.nvim_win_get_cursor(0)) --[[@as integer, integer]]
  vim.api.nvim_buf_set_lines(0, row, row, true, { "- [ ] " })
  vim.api.nvim_win_set_cursor(0, { row + 1, col })
  vim.cmd.startinsert { bang = true }
end, { buffer = true })
