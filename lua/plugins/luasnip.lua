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
    keymap.set({ "i" }, "<C-j>", function()
      vim.schedule(function()
        -- NOTE: this function populates the snippet cache. blink.cmp uses it
        -- on InsertCharPre, which causes the cache to sometimes be outdated.
        -- So, I need to manually call this function to be sure that it's
        -- always udpated
        if not ls.expandable() then return end
        ls.expand {}
      end)
      return "<c-g>u"
    end, { expr = true })
    -- TODO: make jumpable only if inside snippet. check api
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
