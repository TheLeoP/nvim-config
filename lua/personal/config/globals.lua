vim.g.lsp_borders = { "┏", "━", "┓", "┃", "┛", "━", "┗", "┃" }

if vim.fn.has "win32" == 1 then
  vim.g.documentos = "D:/Lucho"
else
  vim.g.documentos = vim.api.nvim_eval "$HOME" .. "/Documentos"
end
