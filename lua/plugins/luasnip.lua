local keymap = vim.keymap
local api = vim.api

return {
  "L3MON4D3/LuaSnip",
  opts = {
    keep_roots = true,
    link_roots = true,
    link_children = true,
    exit_roots = false,
    update_events = { "TextChanged", "TextChangedI" },
    store_selection_keys = "<c-j>",
    enable_autosnippets = true,
  },
  config = function(_, opts)
    local ls = require "luasnip"
    ls.setup(opts)

    local g = api.nvim_create_augroup("personal-luasnip", { clear = true })
    api.nvim_create_autocmd("User", {
      group = g,
      pattern = "LuasnipPreExpand",
      callback = function()
        vim.go.undolevels = vim.go.undolevels
      end,
    })
    keymap.set("i", "<C-j>", function()
      -- NOTE: this function populates the snippet cache. blink.cmp uses it
      -- on InsertCharPre, which causes the cache to sometimes be outdated.
      -- So, I need to manually call this function to be sure that it's
      -- always updated
      if not ls.expandable() then return end
      ls.expand {}
    end)
    keymap.set({ "i", "s" }, "<right>", function()
      if not ls.locally_jumpable(1) then return end
      ls.jump(1)
    end)
    keymap.set({ "i", "s" }, "<left>", function()
      if not ls.locally_jumpable(-1) then return end
      ls.jump(-1)
    end)

    keymap.set("i", "<a-b>", function()
      if ls.choice_active() then require "luasnip.extras.select_choice"() end
    end)

    keymap.set({ "i", "s" }, "<C-b>", function()
      if ls.choice_active() then ls.change_choice(1) end
    end)

    vim.cmd.source(vim.fn.stdpath "config" .. "/lua/personal/snippets.lua")
  end,
}
