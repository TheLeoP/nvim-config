local lpeg = vim.lpeg
local P, S, V, R, C, Cg, Cmt, Cb, Ct, Cc =
  lpeg.P, lpeg.S, lpeg.V, lpeg.R, lpeg.C, lpeg.Cg, lpeg.Cmt, lpeg.Cb, lpeg.Ct, lpeg.Cc
local locale = lpeg.locale {} ---@type table<string, vim.lpeg.Pattern>
local alpha = locale.alpha
local digit = locale.digit
local alnum = locale.alnum
local quote = P '"' + P "'"

local ls = require "luasnip"
local fmt = require("luasnip.extras.fmt").fmt
local t = ls.text_node
local i = ls.insert_node
local sn = ls.snippet_node

local trace = require("personal.pegdebug").trace

local insert_value = function(acc, value)
  acc.value = acc.value or {}
  table.insert(acc.value, value)
  return acc
end

-- TODO: support shortcuts
local emmet_grammar =
  ---@diagnostic disable-next-line: missing-fields
  P {
    "line",
    identifier = alpha ^ 1,
    -- TODO: this can be not only be alnum, add other chars
    value = Ct(
      ((alnum ^ 1) % insert_value)
        * ((P "$" ^ 1) % insert_value * (P "@" * (P "-" * Cg(Cc(true), "descending")) ^ -1 * Cg(
          digit ^ 0 / tonumber,
          "base"
        )) ^ -1) ^ 0
        * (alnum ^ 1 % insert_value) ^ -1
    ),
    -- TODO: allow empty attributes
    -- TODO: support attribute being a value to expand `$$$`
    attribute = C(V "identifier") * P "=" * (Cg(quote, "open_quote") * C(
      Cmt(C(P(1)) * Cb "open_quote", function(_, _, char, open_quote)
        return char ~= open_quote
      end) ^ 0
    ) * Cmt(C(quote) * Cb "open_quote", function(_, _, open_quote, close_quote)
      return open_quote == close_quote
    end) + V "value"),
    class_propertie = P "." * Cc "class" * V "value",
    id_propertie = P "#" * Cc "id" * V "value",
    custom_propertie = (P "[" * Cc "custom" * Ct(((V "attribute" * P " " + V "attribute") % rawset) ^ 1) * P "]"),
    -- TODO: support text being a value to expand `$$$`
    text_propertie = P "{" * Cc "text" * C((-P "}" * P(1)) ^ 0) * P "}",
    propertie = (
      (V "class_propertie" + V "id_propertie" + V "custom_propertie" + V "text_propertie")
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
    tag = Cg(-V "identifier" ^ 2 * V "identifier" ^ 1, "name") * (V "propertie" ^ 0)
      + Cg(V "identifier" ^ -1, "name") * (V "propertie" ^ 1)
      + Cg(V "text_propertie" / 2, "text"),
    operator = (S ">+" + P "^" ^ 1) % function(acc, operator)
      acc.operators = acc.operators or {}
      table.insert(acc.operators, operator)
      return acc
    end,
    grouping = P "(" * V "partial_line" * P ")",
    -- TODO: this only accepts `amount` after `properties`, but it looks like it can also be specified before
    tag_or_grouping = Ct((V "grouping" + V "tag") * (P "*" * (digit ^ 1 % function(acc, amount)
      acc.amount = tonumber(amount)
      return acc
    end)) ^ -1) % function(acc, tag)
      acc.tags = acc.tags or {}
      table.insert(acc.tags, tag)
      return acc
    end,
    tag_or_grouping_with_operator = ((V "tag_or_grouping" * V "operator") + V "tag_or_grouping"),
    partial_line = V "tag_or_grouping_with_operator" ^ 1,
    line = Ct(V "partial_line") * P(-1),
  }

---@class emmet.Value
---@field value string[]
---@field descending boolean|nil
---@field base integer|nil

---@class emmet.TagInfo
---@field name string|nil
---@field amount integer|nil
---@field id emmet.Value|nil
---@field classes emmet.Value[]|nil
---@field attributes table<string, string>|nil
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
  local children = tag.children and vim
    .iter(tag.children)
    :map(function(child)
      return tostring(child)
    end)
    :totable() or {}
  local s = table.concat(children, "")

  if tag.name == "_root" then return s end

  local classes = tag.classes
      and (' class="%s"'):format(table.concat(
        vim
          .iter(tag.classes)
          :map(function(value)
            return table.concat(value.value)
          end)
          :totable(),
        " "
      ))
    or ""

  local id = tag.id and (' id="%s"'):format(table.concat(tag.id.value)) or ""

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
  if not value.value[2] then return value.value[1] end

  local base = value.base or 1
  local descending = not not value.descending

  index = descending and amount + base - index or base + index - 1

  value.value[2] = ("%0" .. value.value[2]:len() .. "d"):format(index)

  return table.concat(value.value, "")
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

      -- NOTE: grouping amount value expansion
      if tree_amount > 1 and not tag.amount then
        if tag.id then tag.id.value = { parse_value(tag.id, j, tree_amount) } end
        if tag.classes then
          vim.iter(tag.classes):each(function(c)
            c.value = { parse_value(c, j, tree_amount) }
          end)
        end
      end

      -- NOTE: tag amount value expansion
      local amount = tag.amount or 1
      for index = 1, amount do
        local expanded_tag = vim.deepcopy(tag)
        if expanded_tag.id then expanded_tag.id.value = { parse_value(expanded_tag.id, index, tree_amount) } end
        if expanded_tag.classes then
          vim.iter(expanded_tag.classes):each(function(c)
            c.value = { parse_value(c, index, tree_amount) }
          end)
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
  local parsed = emmet_grammar:match(text) ---@type emmet.Parsed|nil

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
  if tag.id then id = (' id="%s"'):format(tag.id.value[1]) end
  local class = ""
  if tag.classes then
    local classes = vim
      .iter(tag.classes)
      :map(function(c)
        return c.value[1]
      end)
      :totable()
    class = (' class="%s"'):format(table.concat(classes, " "))
  end
  local custom_attributes = ""
  if tag.attributes then
    custom_attributes = table.concat(
      -- TODO: keep track of the type of quote? This will break otherwise
      -- TODO: or maybe handle differently `"` inside of attributes defined with `'`
      vim.list_extend(
        { "" },
        vim
          .iter(tag.attributes)
          :map(function(key, value)
            return ('%s="%s"'):format(key, value)
          end)
          :totable()
      ),
      " "
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
        ---@diagnostic disable-next-line: no-unknown
        id = id,
        ---@diagnostic disable-next-line: no-unknown
        class = class,
        ---@diagnostic disable-next-line: no-unknown
        text = text,
        ---@diagnostic disable-next-line: no-unknown
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
      ---@diagnostic disable-next-line: no-unknown
      id = id,
      ---@diagnostic disable-next-line: no-unknown
      class = class,
      ---@diagnostic disable-next-line: no-unknown
      text = text,
      ---@diagnostic disable-next-line: no-unknown
      custom_attributes = custom_attributes,
    }
  )
end

return M
