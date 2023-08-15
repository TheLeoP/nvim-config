(import-macros {: map!} :hibiscus.vim)

(map! [n] :<leader>x #(match vim.bo.filetype
                           :lua (do
                                  (vim.cmd "silent! write")
                                  (vim.cmd "source %")
                                  nil)
                           :vim (do
                                  (vim.cmd "silent! write")
                                  (vim.cmd "source %")
                                  nil)
                           :fennel (do
                                     (vim.cmd.FnlBuffer)
                                     nil))
      "Execute current buffer (vim, lua or fennel)")

(map! [n] :<leader><leader>t "<cmd>tab split<cr>")
