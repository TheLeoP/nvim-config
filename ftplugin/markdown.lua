vim.wo.spell = true
vim.bo.spelllang = "es,en"
vim.wo.wrap = true
vim.wo.linebreak = true
vim.wo.breakindent = true
vim.wo.colorcolumn = 0
vim.wo.conceallevel = 3

vim.keymap.set("n", "<leader>sc", "z=", { buffer = true })
vim.keymap.set("n", "<leader>sg", "zg", { buffer = true })
vim.keymap.set("n", "<leader>sug", "zug", { buffer = true })
vim.keymap.set("n", "<leader>sw", "zw", { buffer = true })
vim.keymap.set("n", "<leader>suw", "zuw", { buffer = true })

vim.keymap.set("n", "j", "v:count ? 'j' : 'gj'", { buffer = true, expr = true })
vim.keymap.set("n", "k", "v:count ? 'k' : 'gk'", { buffer = true, expr = true })
vim.keymap.set("n", "gj", "j", { buffer = true })
vim.keymap.set("n", "gk", "k", { buffer = true })

vim.keymap.set("x", "<leader>b", "S*gvS*", { buffer = true })
vim.keymap.set("x", "<leader>i", "S*", { buffer = true })

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
