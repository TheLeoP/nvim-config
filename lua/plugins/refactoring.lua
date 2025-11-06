local keymap = vim.keymap

return {
  "theprimeagen/refactoring.nvim",
  dev = true,
  dependencies = { "lewis6991/async.nvim" },
  config = function()
    keymap.set({ "n", "x" }, "<leader>ae", function()
      return require("refactoring").extract_func()
    end, { desc = "Extract Function", expr = true })
    keymap.set("n", "<leader>aee", function()
      return require("refactoring").extract_func() .. "_"
    end, { desc = "Extract Function (line)", expr = true })

    keymap.set({ "n", "x" }, "<leader>aE", function()
      return require("refactoring").extract_func_to_file()
    end, { desc = "Extract Function To File", expr = true })

    keymap.set({ "n", "x" }, "<leader>av", function()
      return require("refactoring").extract_var()
    end, { desc = "Extract Variable", expr = true })

    keymap.set("n", "<leader>avv", function()
      return require("refactoring").extract_var() .. "_"
    end, { desc = "Extract Variable (line)", expr = true })

    keymap.set({ "n", "x" }, "<leader>ai", function()
      return require("refactoring").inline_var()
    end, { desc = "Inline Variable", expr = true })
    keymap.set({ "n", "x" }, "<leader>aI", function()
      return require("refactoring").inline_func()
    end, { desc = "Inline function", expr = true })

    keymap.set({ "n", "x" }, "<leader>as", function()
      return require("refactoring").select_refactor()
    end, { desc = "Select refactor" })

    keymap.set({ "x", "n" }, "<leader>pv", function()
      return require("refactoring.debug").print_var { output_location = "below" }
    end, { desc = "Debug print var above", expr = true })
    keymap.set({ "x", "n" }, "<leader>pvv", function()
      return require("refactoring.debug").print_var { output_location = "below" } .. "_"
    end, { desc = "Debug print var above", expr = true })

    keymap.set({ "x", "n" }, "<leader>pV", function()
      return require("refactoring.debug").print_var { output_location = "above" }
    end, { desc = "Debug print var above", expr = true })
    keymap.set({ "x", "n" }, "<leader>pVV", function()
      return require("refactoring.debug").print_var { output_location = "above" } .. "_"
    end, { desc = "Debug print var above", expr = true })

    keymap.set("n", "<leader>pP", function()
      return require("refactoring.debug").print_loc { output_location = "above" }
    end, { desc = "Debug print location", expr = true })
    keymap.set("n", "<leader>pp", function()
      return require("refactoring.debug").print_loc { output_location = "below" }
    end, { desc = "Debug print location", expr = true })

    keymap.set({ "x", "n" }, "<leader>pc", function()
      return require("refactoring.debug").cleanup { restore_view = true }
    end, { desc = "Debug print clean", expr = true })
  end,
}
