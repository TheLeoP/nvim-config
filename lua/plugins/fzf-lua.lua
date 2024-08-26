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
      glob_separator = "%s%-%-%s",
      rg_glob = true,
      rg_glob_fn = function(query, opts)
        ---@type string, string
        local search_query, glob_args = query:match(("(.*)%s(.*)"):format(opts.glob_separator))
        -- UNCOMMENT TO DEBUG PRINT INTO FZF
        -- if glob_args then io.write(("q: %s -> flags: %s, query: %s\n"):format(query, glob_args, search_query)) end
        return search_query, glob_args
      end,
    },
  },
  config = function(_, opts)
    local fzf = require "fzf-lua"
    fzf.setup(opts)

    vim.keymap.set("n", "<leader>ff", fzf.files)
    vim.keymap.set("n", "<leader>fb", fzf.buffers)
    vim.keymap.set("n", "<leader>fh", fzf.help_tags)
    vim.keymap.set("n", "<leader>fc", fzf.lgrep_curbuf)
    vim.keymap.set("n", "<leader>fr", fzf.resume)
    vim.keymap.set("n", "<leader>fs", function() fzf.live_grep { silent = true } end)
    vim.keymap.set("n", "<leader>fwd", fzf.diagnostics_workspace)

    vim.keymap.set(
      "n",
      "<leader>fi",
      function() fzf.files { prompt = "< Nvim config >", cwd = vim.fn.stdpath "config" } end,
      { desc = "Fuzzy search files in nvim config" }
    )

    vim.keymap.set(
      "n",
      "<leader>fI",
      function() fzf.live_grep { prompt = "< Rg nvim_config >", cwd = vim.fn.stdpath "config" } end,
      { desc = "Rg in nvim config" }
    )

    vim.keymap.set("n", "<leader>fp", require("personal.fzf-lua").projects, { desc = "Find projects" })

    vim.keymap.set("n", "z=", spellsuggest_select, { desc = "Shows spelling suggestions" })
  end,
  dependencies = {
    {
      "junegunn/fzf",
      build = function() vim.fn["fzf#install"]() end,
    },
  },
}
