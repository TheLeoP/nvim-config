---@diagnostic disable: no-unknown
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
local fmta = require("luasnip.extras.fmt").fmta
local make_condition = require("luasnip.extras.conditions").make_condition
local conds = require "luasnip.extras.conditions.expand"
local postfix = require("luasnip.extras.postfix").postfix
local types = require "luasnip.util.types"
local parse = require("luasnip.util.parser").parse_snippet
local ms = ls.multi_snippet
local k = require("luasnip.nodes.key_indexer").new_key

local not_in_string = make_condition(function()
  local js_blacklist = { "string", "template_string", "string_fragment" }
  local blacklist_by_ft = {
    lua = { "string", "string_content" },
    javascript = js_blacklist,
    typescript = js_blacklist,
    typescriptreact = js_blacklist,
    javascriptreact = js_blacklist,
  }
  local type = vim.treesitter.get_node():type()
  local ft = vim.o.filetype
  return not vim.list_contains(blacklist_by_ft[ft], type)
end)

ls.add_snippets("all", {
  s("todo", {
    d(1, function()
      local commentstring = require("ts_context_commentstring.internal").calculate_commentstring()
        or vim.bo.commentstring
      local template = commentstring:format "<>: <>"
      return sn(
        nil,
        fmta(template, {
          c(1, { t "TODO", t "TODO(TheLeoP)", t "TODO(luis)" }),
          i(2),
        })
      )
    end),
  }),
}, { key = "personal all" })

ls.add_snippets("cs", {
  s(
    { trig = "cl", snippetType = "autosnippet", condition = conds.line_begin },
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
        inside = i(3),
      }
    )
  ),
  s(
    { trig = "fn ", snippetType = "autosnippet", condition = conds.line_begin },
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
        inside = i(5),
      }
    )
  ),
  s(
    { trig = "for ", snippetType = "autosnippet", condition = conds.line_begin },
    fmta(
      [[
<type>
{
    <inside>
}
]],
      {
        inside = i(2),
        type = c(1, {
          sn(
            nil,
            fmta([[for (<init>;<condition>;<step>)]], {
              init = i(1, "int i = 0"),
              condition = i(2, "i < 5"),
              step = i(3, "i++"),
            })
          ),
          sn(
            nil,
            fmta([[foreach (var <element> in <elements>)]], {
              element = i(1, "element"),
              elements = i(2, "elements"),
            })
          ),
        }),
      }
    )
  ),
  s(
    { trig = "if ", snippetType = "autosnippet", condition = conds.line_begin },
    fmta(
      [[
if (<condition>)
{
    <inside>
}
]],
      {
        inside = i(2),
        condition = i(1, "true"),
      }
    )
  ),
}, { key = "personal cs" })

ls.add_snippets("lua", {
  s(
    { trig = "if ", snippetType = "autosnippet", condition = conds.line_begin },
    fmta(
      [[
if <condition> then
  <inside>
end
  ]],
      { condition = i(1), inside = i(2) }
    )
  ),
  s(
    { trig = "elseif ", snippetType = "autosnippet", condition = conds.line_begin },
    fmta(
      [[
elseif <condition> then
  <inside>
]],
      { condition = i(1), inside = i(2) }
    )
  ),
  s(
    { trig = "fn ", snippetType = "autosnippet", condition = conds.line_begin },
    fmta(
      [[
<visibility>function <name>(<args>)
  <inside>
end
]],
      {
        visibility = c(1, { t "local ", t "" }),
        name = i(2),
        args = i(3),
        inside = i(4),
      }
    )
  ),
  s(
    {
      trig = "afn ",
      snippetType = "autosnippet",
      condition = not_in_string,
    },
    fmta(
      [[
function (<args>)
  <inside>
end
]],
      {
        args = i(1),
        inside = i(2),
      }
    )
  ),
  s(
    { trig = "nfor ", snippetType = "autosnippet", condition = conds.line_begin },
    fmta(
      [[
for <start><end><step> do
  <inside>
end
]],
      { start = i(1, "i = 1"), ["end"] = i(2, ", #some_table"), step = i(3, ", 1"), inside = i(4) }
    )
  ),
  s(
    { trig = "for ", snippetType = "autosnippet", condition = conds.line_begin },
    fmta(
      [[
for <iterator> do
  <inside>
end
]],
      {
        iterator = c(1, {
          sn(
            nil,
            fmta(
              [[<i>, <value> in ipairs(<table>)]],
              { i = i(1, "_"), value = i(2, "value"), table = i(3, "some_table") }
            )
          ),
          sn(
            nil,
            fmta(
              [[<key>, <value> in pairs(<table>)]],
              { key = i(1, "key"), value = i(2, "value"), table = i(3, "some_table") }
            )
          ),
          sn(nil, fmta([[<values> in <iterator>]], { values = i(1, "value"), iterator = i(2, "some_iterator()") })),
        }),
        inside = i(2),
      }
    )
  ),
}, { key = "personal lua" })

ls.filetype_extend("typescript", { "javascript" })
ls.filetype_extend("javascriptreact", { "javascript" })
ls.filetype_extend("typescriptreact", { "javascript" })
ls.add_snippets("javascript", {
  s(
    { trig = "if ", snippetType = "autosnippet", condition = conds.line_begin },
    fmta(
      [[
if (<condition>) {
  <inside>
}
]],
      { condition = i(1), inside = i(2) }
    )
  ),
  s(
    { trig = "} else ", snippetType = "autosnippet", condition = conds.line_begin },
    fmta(
      [[
} else {
  <inside>
}
]],
      { inside = i(1) }
    )
  ),
  s(
    { trig = "} elseif ", snippetType = "autosnippet", condition = conds.line_begin },
    fmta(
      [[
} else if (<condition>) {
  <inside>
}
]],
      { condition = i(1), inside = i(2) }
    )
  ),
  s(
    { trig = "afn ", snippetType = "autosnippet", condition = not_in_string },
    fmta(
      [[
  (<args>) =>> {
    <inside>
  }
  ]],
      { args = i(1), inside = i(2) }
    )
  ),
  s(
    { trig = "fn ", snippetType = "autosnippet", condition = not_in_string },
    fmta(
      [[
function <name>(<args>) {
  <inside>
}
]],
      { name = i(1), args = i(2), inside = i(3) }
    )
  ),
}, { key = "personal js" })

ls.add_snippets("markdown", {
  s(
    "code",
    fmta(
      [[
```<lang>
<inside>
```
]],
      { lang = i(1), inside = i(2) }
    )
  ),
}, { key = "personal md" })
