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
    require("fzf-lua").setup(opts)

    vim.keymap.set("n", "<leader>ff", require("fzf-lua").files)
    vim.keymap.set("n", "<leader>fb", require("fzf-lua").buffers)
    vim.keymap.set("n", "<leader>fh", require("fzf-lua").help_tags)
    vim.keymap.set("n", "<leader>fc", require("fzf-lua").lgrep_curbuf)
    vim.keymap.set("n", "<leader>fr", require("fzf-lua").resume)
    vim.keymap.set("n", "<leader>fs", require("fzf-lua").live_grep)
    vim.keymap.set("n", "<leader>fwd", require("fzf-lua").diagnostics_workspace)

    vim.keymap.set(
      "n",
      "<leader>fi",
      function() require("fzf-lua").files { prompt = "< Nvim config >", cwd = vim.fn.stdpath "config" } end,
      { desc = "Fuzzy search files in nvim config" }
    )

    vim.keymap.set(
      "n",
      "<leader>fI",
      function() require("fzf-lua").live_grep { prompt = "< Rg nvim_config >", cwd = vim.fn.stdpath "config" } end,
      { desc = "Rg in nvim config" }
    )

    vim.keymap.set("n", "<leader>fp", require("personal.fzf-lua").projects, { desc = "Find projects" })

    vim.keymap.set("n", "z=", require("fzf-lua").spell_suggest, { desc = "Spelling suggestions" })
  end,
  dependencies = {
    {
      "junegunn/fzf",
      build = function() vim.fn["fzf#install"]() end,
    },
  },
}
