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

local not_in_string_nor_comment = make_condition(function()
  -- even when parsing the tree, it may not be updated in insert mode (?
  -- so manually check for comments
  local commentstring = "^%s*" .. vim.pesc(vim.bo.commentstring:format "")
  local current_line = vim.api.nvim_get_current_line()
  if current_line:match(commentstring) then return false end

  local js_blacklist = { "string", "template_string", "string_fragment", "comment" }
  local blacklist_by_ft = {
    lua = { "string", "string_content", "comment", "comment_content" },
    javascript = js_blacklist,
    typescript = js_blacklist,
    typescriptreact = js_blacklist,
    javascriptreact = js_blacklist,
  }

  vim.treesitter.get_parser():parse()
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
    { trig = "if ", snippetType = "autosnippet", condition = conds.line_begin * conds.line_end },
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
    { trig = "if ", snippetType = "autosnippet", condition = conds.line_begin * conds.line_end },
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
    { trig = "elseif ", snippetType = "autosnippet", condition = conds.line_begin * conds.line_end },
    fmta(
      [[
elseif <condition> then
  <inside>
]],
      { condition = i(1), inside = i(2) }
    )
  ),
  s(
    { trig = "fn ", snippetType = "autosnippet", condition = conds.line_begin * conds.line_end },
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
      condition = not_in_string_nor_comment,
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
for <var> = <value>, <end> do
  <inside>
end
]],
      { var = i(1, "i"), value = i(2, "1"), ["end"] = i(3, "#some_table"), inside = i(4) }
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
  s(
    { trig = "while ", snippetType = "autosnippet", condition = conds.line_begin * conds.line_end },
    fmta(
      [[
while <condition> do
  <inside>
end
  ]],
      { condition = i(1), inside = i(2) }
    )
  ),
  s(
    { trig = "repeat ", snippetType = "autosnippet", condition = conds.line_begin * conds.line_end },
    fmta(
      [[
repeat 
  <inside>
until <condition>
  ]],
      { condition = i(1), inside = i(2) }
    )
  ),
  s(
    { trig = "do ", snippetType = "autosnippet", condition = conds.line_begin * conds.line_end },
    fmta(
      [[
do
  <inside>
end
  ]],
      { inside = i(1) }
    )
  ),
  s(
    { trig = "re" },
    fmta(
      [[
local <name> = require("<module>")
  ]],
      {
        module = i(1),
        name = f(function(args)
          local text = args[1][1]
          if not text then return "" end
          return text:match "%.?([^%.]*)$"
        end, { 1 }),
      }
    )
  ),
}, { key = "personal lua" })

ls.filetype_extend("typescript", { "javascript" })
ls.filetype_extend("javascriptreact", { "javascript" })
ls.filetype_extend("typescriptreact", { "javascript" })
ls.add_snippets("javascript", {
  s(
    { trig = "if ", snippetType = "autosnippet", condition = conds.line_begin * conds.line_end },
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
    { trig = "} elseif ", snippetType = "autosnippet", condition = conds.line_begin * conds.line_end },
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
    { trig = "afn ", snippetType = "autosnippet", condition = not_in_string_nor_comment },
    fmta([[(<args>) =>> <body>]], {
      args = i(1),
      body = c(2, {
        sn(nil, fmta([[<inside>]], { inside = i(1) })),
        sn(
          nil,
          fmta(
            [[{
                <inside>
        }]],
            { inside = i(1) }
          )
        ),
      }),
    })
  ),
  s(
    { trig = "fn ", snippetType = "autosnippet", condition = not_in_string_nor_comment },
    fmta(
      [[
function <name>(<args>) {
  <inside>
}
]],
      { name = i(1), args = i(2), inside = i(3) }
    )
  ),
  s(
    { trig = "while ", snippetType = "autosnippet", condition = not_in_string_nor_comment },
    fmta(
      [[
while (<condition>) {
  <inside>
}
]],
      { condition = i(1), inside = i(2) }
    )
  ),
  s(
    { trig = "for ", snippetType = "autosnippet", condition = not_in_string_nor_comment },
    fmta(
      [[
for (const <name> of <list>) {
  <inside>
}
]],
      { name = i(1), list = i(2), inside = i(3) }
    )
  ),
  s(
    { trig = "try ", snippetType = "autosnippet", condition = not_in_string_nor_comment },
    fmta(
      [[
try {
  <try>
} catch (e) {
  <catch>
}
]],
      { try = i(1), catch = i(2) }
    )
  ),
  s(
    { trig = "switch ", snippetType = "autosnippet", condition = not_in_string_nor_comment },
    fmta(
      [[
switch (<var>) {
  <inside>
}
]],
      { var = i(1), inside = i(2) }
    )
  ),
  s(
    { trig = "case ", snippetType = "autosnippet", condition = not_in_string_nor_comment },
    fmta(
      [[
case <value>: {
  <inside>
  break
}
]],
      { value = i(1), inside = i(2) }
    )
  ),
  s(
    { trig = "usestate ", snippetType = "autosnippet", condition = not_in_string_nor_comment },
    fmta("const [<var>, <setter>] = useState(<initial>)", {
      var = i(1),
      setter = f(function(args)
        local var = args[1][1]
        if not var then return "" end
        return "set" .. var:sub(1, 1):upper() .. var:sub(2)
      end, { 1 }),
      initial = i(2),
    })
  ),
  s(
    { trig = "useeffect ", snippetType = "autosnippet", condition = not_in_string_nor_comment },
    fmta(
      [=[
useEffect(() =>> {
  <inside>
}, [<dependencies>])]=],
      {
        inside = i(1),
        dependencies = i(2),
      }
    )
  ),
}, { key = "personal js" })

ls.add_snippets("markdown", {
  s(
    "c",
    fmta(
      [[
```<lang>
<inside>
```
]],
      { lang = i(1), inside = i(2) }
    )
  ),
  s("b", fmta("**<inside>**", { inside = i(1) })),
  s("i", fmta("*<inside>*", { inside = i(1) })),
  s("bi", fmta("***<inside>***", { inside = i(1) })),
  s("s", fmta("~~<inside>~~", { inside = i(1) })),
  s("img", fmta("![<name>](<url>)", { name = i(1), url = i(2) })),
  s("link", fmta("[<name>](<url>)", { name = i(1), url = i(2) })),
}, { key = "personal md" })

ls.add_snippets("c", {
  s(
    { trig = "for ", snippetType = "autosnippet", condition = conds.line_begin },
    fmta(
      [[
for (<init>;<condition>;<step>)
{
    <inside>
}
]],
      {
        inside = i(4),
        init = i(1, "int i = 0"),
        condition = i(2, "i < 5"),
        step = i(3, "i++"),
      }
    )
  ),
  s(
    { trig = "if ", snippetType = "autosnippet", condition = conds.line_begin * conds.line_end },
    fmta(
      [[
if (<condition>) {
    <inside>
}
]],
      {
        inside = i(2),
        condition = i(1, "true"),
      }
    )
  ),
  s(
    { trig = "} else ", snippetType = "autosnippet", condition = conds.line_begin * conds.line_end },
    fmta(
      [[
} else {
  <inside>
}
]],
      {
        inside = i(1),
      }
    )
  ),
  s(
    { trig = "} elseif ", snippetType = "autosnippet", condition = conds.line_begin * conds.line_end },
    fmta(
      [[
} else if (<condition>) {
  <inside>
}
]],
      {
        condition = i(1),
        inside = i(2),
      }
    )
  ),
}, { key = "personal cs" })
