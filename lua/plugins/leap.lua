local keymap = vim.keymap
local api = vim.api

return {
  {
    "ggandor/leap.nvim",
    dependencies = { "tpope/vim-repeat" },
    config = function()
      local leap = require "leap"
      leap.opts.equivalence_classes = { " \t\r\n", "([{", ")]}", "'\"`" }

      keymap.set({ "n", "x", "o" }, "st", function()
        leap.leap { offset = -1, inclusive_op = true }
      end, { desc = "leap until" })
      keymap.set({ "n", "x", "o" }, "sf", function()
        leap.leap { inclusive_op = true }
      end, { desc = "leap find" })

      keymap.set({ "n", "x", "o" }, "sT", function()
        leap.leap { backward = true, offset = 1, backward_inclusive = true }
      end, { desc = "leap until backward" })
      keymap.set({ "n", "x", "o" }, "sF", function()
        leap.leap { backward = true, backward_inclusive = true }
      end, { desc = "leap find backward" })
      api.nvim_create_augroup("personal-leap", { clear = true })
      api.nvim_create_autocmd("User", {
        pattern = "LeapEnter",
        group = "personal-leap",
        callback = function()
          local mode = vim.api.nvim_get_mode().mode
          if (mode ~= "v" and mode ~= "V" and mode ~= "\22" and mode ~= "n") and leap.state.args.backward_inclusive then
            -- NOTE: force characterwise visual mode to make backwards
            -- operations inclusive
            vim.cmd.normal "v"
          end
        end,
      })
      api.nvim_create_autocmd("User", {
        pattern = "LeapEnter",
        group = "personal-leap",
        callback = function()
          -- NOTE: create a jumplist entry before each jump
          vim.cmd.normal "m'"
        end,
      })

      keymap.set({ "n", "x", "o" }, "sn", function()
        require("leap.treesitter").select()
      end, { desc = "leap treesitter" })

      keymap.set({ "x", "o" }, "ir", function()
        local ok, char = pcall(vim.fn.getcharstr)
        if not ok or char == "\27" or not char then return end

        require("leap.remote").action { input = "i" .. char }
      end, { desc = "leap inside textobject" })

      keymap.set({ "x", "o" }, "ar", function()
        local ok, char = pcall(vim.fn.getcharstr)
        if not ok or char == "\27" or not char then return end

        require("leap.remote").action { input = "a" .. char }
      end, { desc = "leap around textobject" })

      keymap.set({ "x", "o" }, "rr", function()
        require("leap.remote").action { input = "_" }
      end, { desc = "leap line textobject" })

      vim.api.nvim_set_hl(0, "LeapMatch", {
        fg = "#ccff88",
        underline = true,
        nocombine = true,
      })
      vim.api.nvim_set_hl(0, "LeapLabel", {
        fg = "black",
        bg = "#ccff88",
        nocombine = true,
      })
    end,
  },
}
