return {
  "Shatur/neovim-session-manager",
  dependencies = { "nvim-lua/plenary.nvim" },
  config = function()
    local Path = require "plenary.path"
    require("session_manager").setup {
      sessions_dir = Path:new(vim.fn.stdpath "data", "sessions"),
      path_replacer = "__",
      colon_replacer = "++",
      autoload_mode = require("session_manager.config").AutoloadMode.Disabled,
      autosave_last_session = true,
      autosave_ignore_not_normal = true,
      autosave_ignore_dirs = {},
      autosave_ignore_filetypes = {
        "gitcommit",
      },
      autosave_ignore_buftypes = {},
      autosave_only_in_session = false,
      max_path_length = 80,
    }

    local config_group = vim.api.nvim_create_augroup("post-session", {})

    vim.api.nvim_create_autocmd({ "User" }, {
      pattern = "SessionLoadPost",
      group = config_group,
      callback = function()
        local cwd = vim.fn.getcwd()
        local exrc = vim.fs.find({ ".nvim.lua", ".nvimrc", ".exrc" }, { path = cwd, type = "file" })[1]
        if not exrc then return end
        local content = vim.secure.read(exrc)
        if not content then return end
        loadstring(content)()
      end,
    })
  end,
}
