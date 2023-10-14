(import-macros {: map!} :hibiscus.vim)

(fn search-nvim-config []
  (let [builtin (require :telescope.builtin)]
    (builtin.find_files {
                         :prompt_title "< Nvim config >"
                         :cwd (vim.fn.stdpath :config)})))
                        
(map! [n] :<leader>fi search-nvim-config "Fuzzy search files in nvim config")

(fn rg-nvim-config []
  (let [telescope (require :telescope)]
    (telescope.extensions.live_grep_args.live_grep_args {
                                                         :prompt_title "< Rg nvim_config >"
                                                         :cwd (vim.fn.stdpath :config)})))
                                                    
(map! [n] :<leader>fI rg-nvim-config "Rg in nvim config")
