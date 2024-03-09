local ls = require "luasnip"
local s = ls.snippet
local sn = ls.snippet_node
local isn = ls.indent_snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local events = require "luasnip.util.events"
local ai = require "luasnip.nodes.absolute_indexer"
local extras = require "luasnip.extras"
local l = extras.lambda
local rep = extras.rep
local p = extras.partial
local m = extras.match
local n = extras.nonempty
local dl = extras.dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local conds = require "luasnip.extras.expand_conditions"
local postfix = require("luasnip.extras.postfix").postfix
local types = require "luasnip.util.types"
local parse = require("luasnip.util.parser").parse_snippet
local ms = ls.multi_snippet
local k = require("luasnip.nodes.key_indexer").new_key

ls.add_snippets("all", {
  s("todo", {
    d(1, function()
      local template = vim.o.commentstring:format "<>: <>"
      return sn(
        nil,
        fmta(template, {
          c(1, { t "TODO", t "TODO(TheLeoP)", t "TODO(luis)" }),
          i(2),
        })
      )
    end),
  }, {}),
}, { key = "personal all" })

ls.add_snippets("cs", {
  s(
    "cl",
    fmta(
      [[
<visibility> class <name>
{
    <inside>
}
  ]],
      {
        visibility = c(
          2,
          { t "public", t "private", t "protected", t "internal", t "protected internal", t "private protected" }
        ),
        name = i(1),
        inside = i(0),
      }
    )
  ),
  s(
    "fn",
    fmta(
      [[
<visibility> <return_type> <name> (<args>)
{
    <inside>
}
  ]],
      {
        visibility = c(
          4,
          { t "public", t "private", t "protected", t "internal", t "protected internal", t "private protected" }
        ),
        return_type = i(2),
        name = i(1),
        args = i(3),
        inside = i(0),
      }
    )
  ),
}, { key = "personal cs" })
