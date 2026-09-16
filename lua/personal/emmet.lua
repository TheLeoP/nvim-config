local lpeg = vim.lpeg
local P, S, V, R, C, Cg, Cmt, Cb, Ct, Cc =
  lpeg.P, lpeg.S, lpeg.V, lpeg.R, lpeg.C, lpeg.Cg, lpeg.Cmt, lpeg.Cb, lpeg.Ct, lpeg.Cc
local locale = lpeg.locale {} ---@type table<string, vim.lpeg.Pattern>
local digit = locale.digit
local quote = P '"' + P "'"
local space = locale.space

local ls = require "luasnip"
local fmt = require("luasnip.extras.fmt").fmt
local t = ls.text_node
local i = ls.insert_node
local sn = ls.snippet_node

-- TODO: support shortcuts
local emmet_grammar = P {
  "line",
  non_special_char = -(S ">+^.#[]{}()*\"'=$" + space) * P(1),
  identifier = V "non_special_char" ^ 1,
  value = Ct(
    Ct(
      Cg(V "identifier", "text")
        + (
          Cg(P "$" ^ 1, "count_text")
          * (P "@" * (P "-" * Cg(Cc(true), "descending")) ^ -1 * Cg(digit ^ 0 / tonumber, "base")) ^ -1
        )
    ) ^ 1
  ),
  open_quote = Cg(quote, "open_quote"),
  close_quote = Cmt(C(quote) * Cb "open_quote", function(_, _, open_quote, close_quote)
    return open_quote == close_quote
  end),
  -- TODO: support `non_quote` being a `value` to expand `$$$` (instead of
  -- hardcoding its content as a "text" value)
  non_quote = Ct(Ct(Cg(Cmt(C(P(1)) * Cb "open_quote", function(_, _, char, open_quote)
    return char ~= open_quote
  end) ^ 0, "text"))),
  -- TODO: allow empty attributes
  -- TODO: support this `identifier` being a `value` to expand `$$$` (also
  -- requires changes in `build_tree` to expand it)
  attribute = C(V "identifier") * P "=" * (V "open_quote" * V "non_quote" * V "close_quote" + V "value"),
  class_property = P "." * Cc "class" * V "value",
  id_property = P "#" * Cc "id" * V "value",
  custom_property = (P "[" * Cc "custom" * Ct(((V "attribute" * P " " + V "attribute") % rawset) ^ 1) * P "]"),
  -- TODO: support text being a `value` to expand `$$$`
  text_property = P "{" * Cc "text" * C((-P "}" * P(1)) ^ 0) * P "}",
  property = (
    (V "class_property" + V "id_property" + V "custom_property" + V "text_property")
    % function(acc, type, capture)
      if type == "class" then
        acc.classes = acc.classes or {}
        table.insert(acc.classes, capture)
      elseif type == "id" then
        acc.id = capture
      elseif type == "custom" then
        ---@cast capture table<string, string>
        acc.attributes = acc.attributes or {}
        acc.attributes = vim.tbl_extend("force", acc.attributes, capture)
      elseif type == "text" then
        acc.text = capture
      end
      return acc
    end
  ),
  -- TODO: in theory, I shouldn't accept tags with more than 1 `amount` as
  -- valid. This allows `amount` to be anywhere among the property list, but
  -- accepts strings with multiple `amount`s and only uses the last one.
  tag = Cg(-V "identifier" ^ 2 * V "identifier" ^ 1, "name") * ((V "property" + V "amount") ^ 0)
    + Cg(V "identifier" ^ -1, "name") * (-V "property" ^ 2 * V "property" ^ 1) * ((V "property" + V "amount") ^ 0)
    + Cg(V "text_property" / 2, "text") * (V "amount" ^ -1),
  operator = (S ">+" + P "^" ^ 1) % function(acc, operator)
    acc.operators = acc.operators or {}
    table.insert(acc.operators, operator)
    return acc
  end,
  amount = P "*" * Cg(digit ^ 1 / tonumber, "amount"),
  grouping = P "(" * V "partial_line" * P ")" * (V "amount") ^ -1,
  -- TODO: this only accepts `amount` after `property`s, but it can also be specified before
  tag_or_grouping = Ct((V "grouping" + V "tag")) % function(acc, tag)
    acc.tags = acc.tags or {}
    table.insert(acc.tags, tag)
    return acc
  end,
  tag_or_grouping_with_operator = ((V "tag_or_grouping" * V "operator") + V "tag_or_grouping"),
  partial_line = V "tag_or_grouping_with_operator" ^ 1,
  line = Ct(V "partial_line") * P(-1),
}

---@class emmet.ValueContentText
---@field text string

---@class emmet.ValueContentCount
---@field count_text string
---@field descending boolean|nil
---@field base integer|nil

---@alias emmet.ValueContent emmet.ValueContentText|emmet.ValueContentCount
---@alias emmet.Value emmet.ValueContent[]

---@class emmet.TagInfo
---@field name string|nil
---@field amount integer|nil
---@field id emmet.Value|nil
---@field classes emmet.Value[]|nil
---@field attributes table<string, emmet.Value>|nil
---@field text string|nil

---@class emmet.Tag: emmet.TagInfo
---@field children emmet.Tag[]|nil
---@field parent emmet.Tag|nil
---@field indent fun(self: emmet.Tag): string

---@class emmet.Parsed
---@field operators string[]
---@field tags (emmet.TagInfo|emmet.Parsed)[]
---@field amount integer|nil

---@param tag emmet.Tag
---@return string
local function indent(tag)
  local acc = {}
  local current = tag.parent
  while current do
    current = current.parent
    table.insert(acc, "  ")
  end
  table.remove(acc, 1)
  return table.concat(acc)
end

---@param tag emmet.Tag
local function tag_tostring(tag)
  local children = tag.children
      and vim
        .iter(tag.children)
        :map(function(child)
          return tostring(child)
        end)
        :totable()
    or {}
  local s = table.concat(children, "")

  if tag.name == "_root" then return s end

  local classes = tag.classes
      and (' class="%s"'):format(table.concat(
        vim
          .iter(tag.classes)
          :map(
            ---@param value emmet.Value
            function(value)
              return vim
                .iter(value)
                :map(
                  ---@param content emmet.ValueContent
                  function(content)
                    return content.text
                  end
                )
                :join ""
            end
          )
          :totable(),
        " "
      ))
    or ""

  local id = tag.id
      and (' id="%s"'):format(vim
        .iter(tag.id)
        :map(
          ---@param content emmet.ValueContent
          function(content)
            return content.text
          end
        )
        :join "")
    or ""

  local text = tag.text or ""
  text = text .. "\n"

  local indentation = indent(tag)

  local str = ([[
%s<%s%s%s>
%s%s%s</%s>
]]):format(indentation, tag.name, classes, id, s, text, indentation, tag.name)

  if tag.amount then
    local out = {}
    for _ = 1, tag.amount do
      table.insert(out, str)
    end
    str = table.concat(out, "")
  end

  return str
end
local mt = {
  __tostring = tag_tostring,
  __index = {
    indent = indent,
  },
}

---@param value emmet.Value
---@param index integer
---@param amount integer
---@return string
local function parse_value(value, index, amount)
  local out = vim
    .iter(value)
    :map(
      ---@param content emmet.ValueContent
      function(content)
        if content.text then return content.text end

        local base = content.base or 1
        local descending = content.descending ~= nil
        local content_index = descending and amount + base - index or base + index - 1
        return ("%0" .. content.count_text:len() .. "d"):format(content_index)
      end
    )
    :join ""

  return out
end

---@param tags (emmet.TagInfo|emmet.Parsed)[]
---@param operators string[]|nil
---@param root emmet.Tag
---@param first_operator string|nil
---@param tree_amount integer|nil
---@return emmet.Tag
local function build_tree(tags, operators, root, first_operator, tree_amount)
  operators = operators or {}
  tree_amount = tree_amount or 1

  -- NOTE: grouping amount is expanded here
  for j = 1, tree_amount do
    local current_tag = root --[[@as emmet.Tag]]
    for k = 1, #tags do
      local tag = vim.deepcopy(tags[k])
      setmetatable(tag, mt)
      -- NOTE: default to `>` for first node
      local operator = operators[k - 1] or first_operator or ">"

      if tag.tags then
        ---@cast tag -emmet.TagInfo
        local group_root = build_tree(tag.tags, tag.operators, current_tag, operator, tag.amount)

        if operator == ">" then
          -- TODO: fix when `>` if after a count (e.g
          -- `div>(header>ul>li*2>a)+footer>p`). The `a` should be children of
          -- `li`, but they are siblings instead. I may need to expand the
          -- nodes earlier, or maybe the error comes from the fact that I think
          -- I'm treating `*` as creating sibling nodes, and that may cause an
          -- incorrect parent for the `>`
          current_tag = group_root.children[1]
        elseif operator == "+" then
          current_tag = group_root
        elseif operator:find "%^" then
          -- TODO: fix this case, currently is broken. `build_tree` is
          -- returning `current_tag` and it's being used as the next
          -- `current_tag`. But, just like in the non-grouping case, the next
          -- `current_tag` should be the top grandparent reached with the `^`
          -- operator
          current_tag = group_root
        end
        goto continue
      end

      ---@cast tag +emmet.Tag
      ---@cast tag -emmet.Parsed

      -- NOTE: grouping amount value expansion. `tree_amount` is grouping
      -- amount. When tag doesn't have its own ammount, the one from the group
      -- is used
      if tree_amount > 1 and not tag.amount then
        if tag.id then tag.id = { { text = parse_value(tag.id, j, tree_amount) } } end
        if tag.classes then
          tag.classes = vim
            .iter(tag.classes)
            :map(
              ---@param c emmet.Value
              function(c)
                return { { text = parse_value(c, j, tree_amount) } }
              end
            )
            :totable()
        end
        if tag.attributes then
          tag.attributes = vim
            .iter(tag.attributes)
            :map(
              ---@param key string
              ---@param value emmet.Value
              function(key, value)
                return key, { { text = parse_value(value, j, tree_amount) } }
              end
            )
            :fold(
              {},
              ---@param acc table<string, emmet.Value>
              ---@param key string
              ---@param value emmet.Value
              function(acc, key, value)
                acc[key] = value
                return acc
              end
            )
        end
      end

      -- NOTE: tag amount value expansion
      local amount = tag.amount or 1
      for index = 1, amount do
        local expanded_tag = vim.deepcopy(tag)
        if expanded_tag.id then expanded_tag.id = { { text = parse_value(expanded_tag.id, index, tree_amount) } } end
        if expanded_tag.classes then
          expanded_tag.classes = vim
            .iter(expanded_tag.classes)
            :map(
              ---@param c emmet.Value
              function(c)
                return { { text = parse_value(c, index, tree_amount) } }
              end
            )
            :totable()
        end
        if expanded_tag.attributes then
          expanded_tag.attributes = vim
            .iter(expanded_tag.attributes)
            :map(
              ---@param key string
              ---@param value emmet.Value
              function(key, value)
                return key, { { text = parse_value(value, j, tree_amount) } }
              end
            )
            :fold(
              {},
              ---@param acc table<string, emmet.Value>
              ---@param key string
              ---@param value emmet.Value
              function(acc, key, value)
                acc[key] = value
                return acc
              end
            )
        end

        if operator == ">" then
          current_tag.children = current_tag.children or {}
          table.insert(current_tag.children, expanded_tag)
          expanded_tag.parent = current_tag

          if index == amount then current_tag = expanded_tag end
        elseif operator == "+" then
          local parent = assert(current_tag.parent)
          parent.children = parent.children or {}
          table.insert(parent.children, expanded_tag)
          expanded_tag.parent = parent

          if index == amount then current_tag = expanded_tag end
        elseif operator:find "%^" then
          local parent = assert(current_tag.parent)
          local grandparent = parent.parent or root
          for _ = 2, operator:len() do
            grandparent = grandparent.parent or root
          end
          table.insert(grandparent.children, expanded_tag)
          expanded_tag.parent = grandparent

          if index == amount then current_tag = parent end
        end
      end

      ::continue::
    end
  end

  return root
end

local M = {}

function M.parse(text)
  local parsed = emmet_grammar:match(text)
  ---@type emmet.Parsed|nil

  if not parsed then return end

  ---@type emmet.Tag
  local root = setmetatable({
    name = "_root",
  }, mt)
  root = build_tree(parsed.tags, parsed.operators, root)
  return root
end

---@param tag emmet.Tag
---@param jump_index integer|nil
---@return table[]
function M.to_snippet(tag, jump_index)
  jump_index = jump_index or 1

  local child_snips = tag.children
      and vim
        .iter(tag.children)
        :enumerate()
        :map(function(index, child)
          return M.to_snippet(child, index)
        end)
        :flatten()
        :totable()
    or nil

  if tag.name == "_root" then return sn(nil, child_snips) end

  local indentation = tag:indent()
  local text = tag.text or ""

  local id = ""
  if tag.id then id = (' id="%s"'):format(tag.id[1].text) end
  local class = ""
  if tag.classes then
    local classes = vim
      .iter(tag.classes)
      :map(
        ---@param c emmet.Value
        function(c)
          return c[1].text
        end
      )
      :totable()
    class = (' class="%s"'):format(table.concat(classes, " "))
  end
  local custom_attributes = ""
  if tag.attributes then
    custom_attributes = (" %s"):format(
      -- TODO: keep track of the type of quote? This will break otherwise
      -- TODO: or maybe handle differently `"` inside of attributes defined with `'`
      vim
        .iter(tag.attributes)
        :map(
          ---@param key string
          ---@param value emmet.Value
          function(key, value)
            return ('%s="%s"'):format(key, value[1].text)
          end
        )
        :join " "
    )
  end

  -- TODO: correctly support classes with empty `name` (i.e. only text, or infered tag names)
  if not child_snips then
    return fmt(
      [[
{indentation}<{tag_name}{id}{class}{custom_attributes}>{text}{inside}</{tag_name}>]],
      {
        ---@diagnostic disable-next-line: no-unknown
        tag_name = t(tag.name),
        ---@diagnostic disable-next-line: no-unknown
        inside = i(jump_index),
        ---@diagnostic disable-next-line: no-unknown
        indentation = t(indentation),
        id = id,
        class = class,
        text = text,
        custom_attributes = custom_attributes,
      }
    )
  end
  -- TODO: instead of adding a newline at the end always (like when it has
  -- children) or never (like when it doesn't have children), use some kind of
  -- join-like logic to only put it between two sibling nodes
  return fmt(
    [[
{indentation}<{tag_name}{id}{class}{custom_attributes}>{text}
{inside}
{indentation}</{tag_name}>
]],
    {
      ---@diagnostic disable-next-line: no-unknown
      tag_name = t(tag.name),
      ---@diagnostic disable-next-line: no-unknown
      inside = sn(jump_index, child_snips),
      ---@diagnostic disable-next-line: no-unknown
      indentation = t(indentation),
      id = id,
      class = class,
      text = text,
      custom_attributes = custom_attributes,
    }
  )
end

return M
