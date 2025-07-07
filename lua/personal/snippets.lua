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
    python = { "string", "string_content", "comment" },
  }

  vim.treesitter.get_parser():parse(true)
  local type = vim.treesitter.get_node():type()
  local ft = vim.o.filetype
  return not vim.list_contains(blacklist_by_ft[ft], type)
end)

---@param line_to_cursor string
---@return string|nil, any[]|nil
local function emmet_matcher(line_to_cursor)
  local emmet = require "personal.emmet"
  -- TODO: can I do something to make this work in jsx files in a line like
  -- `return div>div`?
  local unindented_line_to_cursor = line_to_cursor:match "^%s*(.*)$"
  local root = emmet.parse(unindented_line_to_cursor)
  if not root then return end

  return line_to_cursor, { root }
end

ls.add_snippets("all", {
  s("todo", {
    d(1, function()
      local commentstring = require("ts_context_commentstring.internal").calculate_commentstring()
        or vim.bo.commentstring
      commentstring = commentstring:gsub("<", "<<")
      commentstring = commentstring:gsub(">", ">>")
      local template = commentstring:format "TODO<author>: <text>"
      return sn(
        nil,
        fmta(template, {
          author = c(2, { t "", t "(TheLeoP)", t "(luis)" }),
          text = i(1),
        })
      )
    end),
  }),
  s("note", {
    d(1, function()
      local commentstring = require("ts_context_commentstring.internal").calculate_commentstring()
        or vim.bo.commentstring
      commentstring = commentstring:gsub("<", "<<")
      commentstring = commentstring:gsub(">", ">>")
      local template = commentstring:format "NOTE: <text>"
      return sn(
        nil,
        fmta(template, {
          text = i(1),
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
    {
      trig = "if ",
      snippetType = "autosnippet",
      condition = conds.line_begin * conds.line_end * not_in_string_nor_comment,
    },
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
    {
      trig = "elseif ",
      snippetType = "autosnippet",
      condition = conds.line_begin * conds.line_end * not_in_string_nor_comment,
    },
    fmta(
      [[
elseif <condition> then
  <inside>
]],
      { condition = i(1), inside = i(2) }
    )
  ),
  s(
    {
      trig = "fn ",
      snippetType = "autosnippet",
      condition = conds.line_begin * conds.line_end * not_in_string_nor_comment,
    },
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
    {
      trig = "nfor ",
      snippetType = "autosnippet",
      condition = conds.line_begin * conds.line_end * not_in_string_nor_comment,
    },
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
    {
      trig = "for ",
      snippetType = "autosnippet",
      condition = conds.line_begin * conds.line_end * not_in_string_nor_comment,
    },
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
    {
      trig = "while ",
      snippetType = "autosnippet",
      condition = conds.line_begin * conds.line_end * not_in_string_nor_comment,
    },
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
    {
      trig = "repeat ",
      snippetType = "autosnippet",
      condition = conds.line_begin * conds.line_end * not_in_string_nor_comment,
    },
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
    {
      trig = "do ",
      snippetType = "autosnippet",
      condition = conds.line_begin * conds.line_end * not_in_string_nor_comment,
    },
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
  s({ trig = [[\([a-zA-Z_]\+\) \(+\|-\|\%(\.\.\)\)= ]], trigEngine = "vim", snippetType = "autosnippet" }, {
    d(1, function(_, snip)
      local identifier = snip.captures[1]
      local operator = snip.captures[2]

      return sn(
        nil,
        fmta(
          [[
<identifier> = <identifier> <operator> ]],
          {
            identifier = t(identifier),
            operator = t(operator),
          }
        )
      )
    end),
  }),
  s({ trig = [[\([a-zA-Z_]\+\)\(\%(++\)\|\%(--\)\)]], trigEngine = "vim", snippetType = "autosnippet" }, {
    d(1, function(_, snip)
      local identifier = snip.captures[1]
      local operator = snip.captures[2]
      local operation = operator == "++" and "+ 1" or "- 1"

      return sn(
        nil,
        fmta(
          [[
<identifier> = <identifier> <operation>]],
          {
            identifier = t(identifier),
            operation = t(operation),
          }
        )
      )
    end),
  }),
}, { key = "personal lua" })

ls.filetype_extend("typescript", { "javascript" })
ls.filetype_extend("javascriptreact", { "javascript" })
ls.filetype_extend("typescriptreact", { "javascript", "javascriptreact" })
ls.filetype_extend("html", { "javascriptreact" })
ls.add_snippets("javascript", {
  s(
    { trig = "if ", snippetType = "autosnippet", condition = conds.line_begin * conds.line_end },
    fmta(
      [[
if (<condition>) <body>
]],
      {
        condition = i(1),
        body = c(2, {
          sn(
            nil,
            fmta(
              [[
{
  <inside>
}]],
              { inside = i(1) }
            )
          ),
          i(nil),
        }),
      }
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

ls.add_snippets("javascriptreact", {
  s({
    -- NOTE: trig does nothing here
    trig = "",
    trigEngine = function()
      return emmet_matcher
    end,
  }, {
    d(1, function(_, snip)
      local emmet = require "personal.emmet"
      local root = snip.captures[1] --[[@as emmet.Tag]]
      local snippet = emmet.to_snippet(root)

      return snippet
    end),
  }),
}, { key = "personal jsx" })

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
for (int <var> = <start>; <var_rep> <condition>;<var_rep><step>) {
    <inside>
}
]],
      {
        var = i(1, "i"),
        var_rep = rep(1),
        start = i(2, "0"),
        condition = i(3, "< 5"),
        step = i(4, "++"),
        inside = i(5),
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
  s(
    { trig = "fn ", snippetType = "autosnippet", condition = conds.line_begin * conds.line_end },
    fmta(
      [[
<return_type> <name>(<args>) {
  <inside>
}
]],
      {
        name = i(1, "name"),
        args = i(2),
        return_type = i(3, "void"),
        inside = i(4),
      }
    )
  ),
  s(
    { trig = "struct ", snippetType = "autosnippet", condition = conds.line_begin * conds.line_end },
    fmta(
      [[
typedef struct {
  <inside>
} <name>;
]],
      {
        name = i(1, "name"),
        inside = i(2),
      }
    )
  ),
  s(
    { trig = "switch ", snippetType = "autosnippet", condition = conds.line_begin * conds.line_end },
    fmta(
      [[
switch (<var>) {
  <inside>
}
]],
      {
        var = i(1, "var"),
        inside = i(2),
      }
    )
  ),
  s(
    { trig = "case ", snippetType = "autosnippet", condition = conds.line_begin * conds.line_end },
    fmta(
      [[
case <value>:
  <inside>
  break;
]],
      {
        value = i(1, "value"),
        inside = i(2),
      }
    )
  ),
}, { key = "personal c" })

ls.add_snippets("python", {
  s(
    { trig = "fn ", snippetType = "autosnippet", condition = conds.line_begin },
    fmta(
      [[
def <name>(<args>)<return_type>:
    <inside>
]],
      {
        name = i(1, "name"),
        args = i(2),
        return_type = i(3),
        inside = i(4, "pass"),
      }
    )
  ),
  s(
    { trig = "if ", snippetType = "autosnippet", condition = conds.line_begin * conds.line_end },
    fmta(
      [[
if <condition>:
    <inside>
]],
      {
        condition = i(1, "True"),
        inside = i(2, "pass"),
      }
    )
  ),
  s(
    { trig = "else ", snippetType = "autosnippet", condition = conds.line_begin * conds.line_end },
    fmta(
      [[
else:
    <inside>
]],
      {
        inside = i(1, "pass"),
      }
    )
  ),
  s(
    { trig = "elif ", snippetType = "autosnippet", condition = conds.line_begin * conds.line_end },
    fmta(
      [[
elif <condition>:
    <inside>
]],
      {
        condition = i(1, "True"),
        inside = i(2, "pass"),
      }
    )
  ),
  s(
    { trig = "for ", snippetType = "autosnippet", condition = conds.line_begin * conds.line_end },
    fmta(
      [[
for <item> in <expr>:
  <inside>
]],
      {
        item = i(1, "item"),
        expr = i(2, "expr"),
        inside = i(3, "pass"),
      }
    )
  ),
  s(
    { trig = "afn ", snippetType = "autosnippet", condition = not_in_string_nor_comment },
    fmta(
      [[
lambda <args>: <inside>
]],
      {
        args = i(1, "x"),
        inside = i(2, "pass"),
      }
    )
  ),
}, { key = "personal python" })
