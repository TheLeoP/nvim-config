local keymap = vim.keymap

return {
  "L3MON4D3/LuaSnip",
  opts = {
    update_events = { "TextChanged", "TextChangedI" },
    store_selection_keys = "<c-j>",
    enable_autosnippets = true,
    region_check_events = { "InsertEnter" },
    delete_check_events = { "InsertLeave" },
  },
  config = function(_, opts)
    local ls = require "luasnip"
    ls.setup(opts)
    keymap.set({ "i" }, "<C-j>", function() ls.expand() end)
    keymap.set({ "i", "s" }, "<right>", function() ls.jump(1) end)
    keymap.set({ "i", "s" }, "<left>", function() ls.jump(-1) end)

    keymap.set("i", "<a-b>", function()
      if ls.choice_active() then require "luasnip.extras.select_choice"() end
    end)

    keymap.set({ "i", "s" }, "<C-b>", function()
      if ls.choice_active() then ls.change_choice(1) end
    end)

    vim.cmd.source(vim.fn.stdpath "config" .. "/lua/personal/config/snippets.lua")
  end,
}
