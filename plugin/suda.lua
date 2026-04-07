vim.g["suda#prompt"] = "Contraseña: "
if vim.fn.has "win32" == 0 then vim.g.suda_smart_edit = 1 end

vim.pack.add { "https://github.com/lambdalisue/suda.vim" }
