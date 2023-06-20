return {
  "tpope/vim-fugitive",
  "tpope/vim-rhubarb",
  {
    "lewis6991/gitsigns.nvim",
    opts = {
      signs = {
        add = { text = "+" },
        change = { text = "~" },
        delete = { text = "_" },
        topdelete = { text = "‾" },
        changedelete = { text = "~" },
      },
      signcolumn = false,
      numhl = false,
      linehl = false,
      on_attach = function(bufnr)
        local opts = { buffer = bufnr, expr = true }
        local gs = package.loaded.gitsigns

        vim.keymap.set("n", "[c", function()
          if vim.wo.diff then
            return "[c"
          end
          vim.schedule(function()
            gs.prev_hunk()
          end)
          return "<Ignore>"
        end, opts)
        vim.keymap.set("n", "]c", function()
          if vim.wo.diff then
            return "]c"
          end
          vim.schedule(function()
            gs.next_hunk()
          end)
          return "<Ignore>"
        end, opts)

        -- Actions
        vim.keymap.set({ "n", "v" }, "<leader>hs", ":Gitsigns stage_hunk<CR>")
        vim.keymap.set({ "n", "v" }, "<leader>hr", ":Gitsigns reset_hunk<CR>")
        vim.keymap.set("n", "<leader>hS", gs.stage_buffer)
        vim.keymap.set("n", "<leader>hu", gs.undo_stage_hunk)
        vim.keymap.set("n", "<leader>hR", gs.reset_buffer)
        vim.keymap.set("n", "<leader>hp", gs.preview_hunk)
        vim.keymap.set("n", "<leader>hb", function()
          gs.blame_line { full = true }
        end)
        vim.keymap.set("n", "<leader>tb", gs.toggle_current_line_blame)
        vim.keymap.set("n", "<leader>hd", gs.diffthis)
        vim.keymap.set("n", "<leader>hD", function()
          gs.diffthis "~"
        end)
        vim.keymap.set("n", "<leader>td", gs.toggle_deleted)

        -- Text object
        vim.keymap.set({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>")
      end,
    },
  },
  {
    "sindrets/diffview.nvim",
    opts = {},
    dependencies = {
      "kyazdani42/nvim-web-devicons",
    },
  },
}
