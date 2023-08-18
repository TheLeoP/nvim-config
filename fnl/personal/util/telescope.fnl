(local M {})

(fn M.search_nvim_config []
  (let [builtin (require :telescope.builtin)]
    (builtin.find_files {
                        :prompt_title "< Nvim config >"
                        :cwd (vim.fn.stdpath :config)
                        })))

(fn M.browse_nvim_config []
  (let [telescope (require :telescope)]
    (telescope.extensions.file_browser.file_browser {
                                                    :prompt_title "< Browse nvim_config >"
                                                    :cwd (vim.fn.stdpath :config)
                                                    })))
(fn M.browse_trabajos []
  (let [telescope (require :telescope)]
    (telescope.extensions.file_browser.file_browser {
                                                    :prompt_title "< Browse trabajos >"
                                                    :cwd vim.g.documentos
                                                    })))

(fn M.search_trabajos []
  (let [builtin (require :telescope.builtin)]
    (builtin.find_files {
                        :prompt_title "< Buscar trabajos >"
                        :cwd vim.g.documentos
                        })))


M
