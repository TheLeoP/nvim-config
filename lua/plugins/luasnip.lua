return {
  "L3MON4D3/LuaSnip",
  opts = {
    keep_roots = true,
    link_roots = true,
    link_children = true,
    update_events = { "TextChanged", "TextChangedI" },
  },
  config = function(_, opts)
    local ls = require "luasnip"
    ls.setup(opts)
    vim.keymap.set({ "i" }, "<C-K>", function() ls.expand() end)
    vim.keymap.set({ "i", "s" }, "<C-L>", function() ls.jump(1) end)
    vim.keymap.set({ "i", "s" }, "<C-J>", function() ls.jump(-1) end)

    vim.keymap.set("i", "<c-s>", function()
      if ls.choice_active() then require "luasnip.extras.select_choice"() end
    end)

    vim.keymap.set({ "i", "s" }, "<C-b>", function()
      if ls.choice_active() then ls.change_choice(1) end
    end)

    vim.cmd.source(vim.fn.stdpath "config" .. "/lua/personal/config/snippets.lua")
  end,
}
