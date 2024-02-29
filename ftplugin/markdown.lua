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
    vim.o.operatorfunc = "v:lua." .. fn_name
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
