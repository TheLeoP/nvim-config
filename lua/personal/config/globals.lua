vim.g.lsp_borders = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" }

vim.g.ciclo_actual = "10mo ciclo"

if vim.fn.has "win32" == 1 then
  vim.g.documentos = "D:/Lucho"
else
  vim.g.documentos = vim.api.nvim_eval "$HOME" .. "/Documentos"
end

vim.g.documentos_u = vim.g.documentos .. "/Documentos U/" .. vim.g.ciclo_actual .. "/"
