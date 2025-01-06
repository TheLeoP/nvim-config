local keymap = vim.keymap

return {
  "lewis6991/gitsigns.nvim",
  opts = {
    signs = {
      add = { text = "+" },
      change = { text = "~" },
      delete = { text = "_" },
      topdelete = { text = "‾" },
      changedelete = { text = "~" },
    },
    signcolumn = true,
    on_attach = function(bufnr)
      local gs = require "gitsigns"

      keymap.set("n", "[c", function()
        if vim.wo.diff then
          vim.cmd.normal { "[c", bang = true }
        else
          gs.nav_hunk "prev"
        end
      end, { buffer = bufnr, desc = "Jump to next hunk/change" })
      keymap.set("n", "]c", function()
        if vim.wo.diff then
          vim.cmd.normal { "]c", bang = true }
        else
          gs.nav_hunk "next"
        end
      end, { buffer = bufnr, desc = "Jump to previous hunk/change" })

      -- Actions
      keymap.set({ "n", "x" }, "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
      keymap.set({ "n", "x" }, "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
      keymap.set("n", "<leader>hS", gs.stage_buffer, { desc = "Stage buffer" })
      keymap.set("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
      keymap.set("n", "<leader>hR", gs.reset_buffer, { desc = "Reset buffer" })
      keymap.set("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
      keymap.set("n", "<leader>hb", function() gs.blame_line { full = true } end, { desc = "Blame line" })
      keymap.set("n", "<leader>tb", gs.toggle_current_line_blame, { desc = "Toggle current line blame" })
      keymap.set("n", "<leader>hd", gs.diffthis, { desc = "Diffthis" })
      keymap.set("n", "<leader>hD", function() gs.diffthis "~" end, { desc = "Diffthis ~" })

      -- Text object
      keymap.set({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { desc = "inner hunk" })
    end,
  },
}
