(vim.keymap.set
  [:n]
  :<leader><leader>x
  #(match vim.bo.filetype
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
  {:desc "Execute current buffer (vim, lua or fennel)"})
  


(vim.keymap.set [:n] :<leader><leader>t "<cmd>tab split<cr>")
