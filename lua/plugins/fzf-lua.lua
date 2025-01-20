local keymap = vim.keymap

---@param idx integer
local spell_on_choice = vim.schedule_wrap(function(idx)
  if type(idx) ~= "number" then return end
  vim.cmd("normal! " .. idx .. "z=")
end)

local spellsuggest_select = function()
  if vim.v.count > 0 then
    spell_on_choice(vim.v.count)
    return
  end
  require("fzf-lua").spell_suggest()
end

return {
  "ibhagwan/fzf-lua",
  opts = {
    "telescope",
    grep = {
      glob_separator = "  ",
      rg_glob = true,
      rg_glob_fn = function(query, opts)
        ---@type string, string
        local search_query, glob_args = query:match(("(.*)%s(.*)"):format(opts.glob_separator))
        return search_query, glob_args
      end,
    },
    keymap = {
      fzf = {
        true, -- inherit from defaults
        ["ctrl-c"] = "abort",
      },
    },
    actions = {
      files = {
        ["ctrl-o"] = { fn = require("fzf-lua.actions").toggle_ignore, reuse = true, header = false },
        ["ctrl-h"] = { fn = require("fzf-lua.actions").toggle_hidden, reuse = true, header = false },
        ["ctrl-f"] = { fn = require("fzf-lua.actions").toggle_follow, reuse = true, header = false },
      },
    },
  },
  config = function(_, opts)
    local fzf = require "fzf-lua"
    fzf.setup(opts)

    keymap.set("n", "<leader>ff", fzf.files)
    keymap.set("n", "<leader>fb", fzf.buffers)
    keymap.set("n", "<leader>fh", fzf.help_tags)
    keymap.set("n", "<leader>fc", fzf.lgrep_curbuf)
    keymap.set("n", "<leader>fr", fzf.resume)
    keymap.set("n", "<leader>fs", function() fzf.live_grep { silent = true } end)
    keymap.set("n", "<leader>fwd", fzf.diagnostics_workspace)

    keymap.set(
      "n",
      "<leader>fi",
      function() fzf.files { prompt = "< Fd nvim config >", cwd = vim.fn.stdpath "config" } end,
      { desc = "Fuzzy search files in nvim config" }
    )
    keymap.set(
      "n",
      "<leader>fI",
      function() fzf.live_grep { prompt = "< Rg nvim config >", cwd = vim.fn.stdpath "config" } end,
      { desc = "Rg in nvim config" }
    )

    keymap.set(
      "n",
      "<leader>fl",
      function() fzf.files { prompt = "< Fd plugins >", cwd = vim.fn.stdpath "data" .. "/lazy" } end,
      { desc = "Fuzzy search files in plugins dir" }
    )
    keymap.set(
      "n",
      "<leader>fL",
      function() fzf.live_grep { prompt = "< Rg plugins >", cwd = vim.fn.stdpath "data" .. "/lazy" } end,
      { desc = "Rg in plugins dir" }
    )

    keymap.set("n", "<leader>fp", require("personal.fzf-lua").projects, { desc = "Find projects" })

    keymap.set("n", "z=", spellsuggest_select, { desc = "Shows spelling suggestions" })

    keymap.set("n", "<leader>fgb", fzf.git_branches)
    keymap.set("n", "<leader>fgc", fzf.git_bcommits)
    keymap.set("n", "<leader>fgC", fzf.git_commits)
    keymap.set("n", "<leader>fgs", fzf.git_stash)
    keymap.set("n", "<leader>fg<cr>", fzf.git_status)
  end,
  dependencies = {
    {
      "junegunn/fzf",
      build = ":call fzf#install()",
      init = function()
        local separator = vim.fn.has "win32" == 1 and ";" or ":"
        local fzf_path = vim.fn.stdpath "data" .. "/lazy/fzf/bin"
        fzf_path = vim.fs.normalize(fzf_path)
        vim.env.PATH = vim.env.PATH .. separator .. fzf_path
      end,
      config = function() vim.api.nvim_del_user_command "FZF" end,
    },
  },
}
