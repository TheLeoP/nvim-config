local Scanner = require "lustache.scanner"
local Context = require "lustache.context"

local patterns = {
  eq = "%s*=",
  curly = "%s*}",
  tag = "[#\\^/>{&=!?]",
}

local html_escape_characters = {
  ["&"] = "&amp;",
  ["<"] = "&lt;",
  [">"] = "&gt;",
  ['"'] = "&quot;",
  ["'"] = "&#39;",
  ["/"] = "&#x2F;",
}

local block_tags = {
  ["#"] = true,
  ["^"] = true,
  ["?"] = true,
}

---Low-level function that compiles the given `tokens` into a
---function that accepts two arguments: a Context and a
---Renderer.
---@param tokens lustache.Token[]
---@param original_template string
---@return lustache.CompiledRenderer
local function compile_tokens(tokens, original_template)
  local subs = {} ---@type lustache.CompiledRenderer[]

  ---@param i integer
  ---@param tokens lustache.Token[]
  ---@return lustache.CompiledRenderer
  local function subrender(i, tokens)
    if not subs[i] then
      local fn = compile_tokens(tokens, original_template)
      subs[i] = function(ctx, rnd) return fn(ctx, rnd) end
    end
    return subs[i]
  end

  ---@param ctx lustache.Context
  ---@param rnd lustache.Renderer
  ---@return string
  local function render(ctx, rnd)
    local buf = {} ---@type string[]
    for i, token in ipairs(tokens) do
      local t = token.type
      buf[#buf + 1] = t == "?" and rnd:_conditional(token, ctx, subrender(i, token.tokens))
        or t == "#" and rnd:_section(token, ctx, subrender(i, token.tokens), original_template)
        or t == "^" and rnd:_inverted(token.value, ctx, subrender(i, token.tokens))
        or t == ">" and rnd:_partial(token.value, ctx, original_template)
        or (t == "{" or t == "&") and rnd:_name(token.value, ctx, false)
        or t == "name" and rnd:_name(token.value, ctx, true)
        or t == "text" and token.value
        or ""
    end
    return table.concat(buf)
  end
  return render
end

---@param tags lustache.Tags
---@return lustache.Tags
local function escape_tags(tags)
  return {
    vim.pesc(tags[1]) .. "%s*",
    "%s*" .. vim.pesc(tags[2]),
  }
end

---@param tokens lustache.Token[]
---@return lustache.Token[]
local function nest_tokens(tokens)
  local tree = {} ---@type lustache.Token[]
  local collector = tree
  local sections = {} ---@type lustache.Token[]
  local section ---@type lustache.Token

  for _, token in ipairs(tokens) do
    if block_tags[token.type] then
      token.tokens = {}
      sections[#sections + 1] = token
      collector[#collector + 1] = token
      collector = token.tokens
    elseif token.type == "/" then
      if #sections == 0 then error("Unopened section: " .. token.value) end

      -- Make sure there are no open sections when we're done
      section = table.remove(sections, #sections)

      if not section.value == token.value then error("Unclosed section: " .. section.value) end

      section.closing_tag_index = token.start_index

      if #sections > 0 then
        collector = sections[#sections].tokens
      else
        collector = tree
      end
    else
      collector[#collector + 1] = token
    end
  end

  section = table.remove(sections, #sections)

  if section then error("Unclosed section: " .. section.value) end

  return tree
end

---Combines the values of consecutive text tokens in the given `tokens` array
---to a single token.
---@param tokens lustache.Token[]
---@return lustache.Token
local function squash_tokens(tokens)
  local out, txt = {}, {} ---@type lustache.Token[], string[]
  local txt_start_index, txt_end_index ---@type integer, integer
  for _, v in ipairs(tokens) do
    if v.type == "text" then
      if #txt == 0 then txt_start_index = v.start_index end
      txt[#txt + 1] = v.value
      txt_end_index = v.end_index
    else
      if #txt > 0 then
        out[#out + 1] =
          { type = "text", value = table.concat(txt), start_index = txt_start_index, end_index = txt_end_index }
        txt = {}
      end
      out[#out + 1] = v
    end
  end
  if #txt > 0 then
    out[#out + 1] =
      { type = "text", value = table.concat(txt), start_index = txt_start_index, end_index = txt_end_index }
  end
  return out
end

---@param view lustache.View|nil
---@return lustache.Context|nil
local function make_context(view)
  if not view then return view end
  return getmetatable(view) == Context and view or Context:new(view)
end

---@alias lustache.CompiledRenderer fun(context: lustache.Context, renderer: lustache.Renderer): string

---@alias lustache.PublicCompiledRenderer fun(context: lustache.Context): string

---@alias lustache.Tags {[1]: string, [2]: string}

---@class lustache.Renderer
---@field tags lustache.Tags
---@field cache table<string, lustache.PublicCompiledRenderer>
---@field partial_cache table<string, lustache.PublicCompiledRenderer>
local Renderer = {}

function Renderer:clear_cache()
  self.cache = {}
  self.partial_cache = {}
end

---@class lustache.Token
---@field type "text"| "name" | "[#\\^/>{&=!?]"
---@field value string|nil
---@field end_index integer
---@field start_index integer
---@field closing_tag_index integer|nil
---@field tokens lustache.Token[]|nil

---@param tokens lustache.Token[]|string
---@param tags lustache.Tags|nil
---@param original_template string
---@return lustache.PublicCompiledRenderer
function Renderer:compile(tokens, tags, original_template)
  tags = tags or self.tags
  if type(tokens) == "string" then tokens = self:parse(tokens, tags) end
  ---@cast tokens -string

  local fn = compile_tokens(tokens, original_template)

  return function(view) return fn(make_context(view), self) end
end

---@param template string
---@param view lustache.View
---@param partials lustache.Partial|nil
---@return string
function Renderer:render(template, view, partials)
  if type(self) == "string" then error "Call mustache:render, not mustache.render!" end

  if partials then self.partials = partials end

  if not template then return "" end

  local fn = self.cache[template]

  if not fn then
    fn = self:compile(template, self.tags, template)
    self.cache[template] = fn
  end

  return fn(view)
end

---@param token lustache.Token
---@param context lustache.Context
---@param callback lustache.CompiledRenderer
---@return string
function Renderer:_conditional(token, context, callback)
  local value = context:lookup(token.value)

  if value then return callback(context, self) end

  return ""
end

---@param token lustache.Token
---@param context lustache.Context
---@param callback lustache.CompiledRenderer
---@param original_template string
---@return string
function Renderer:_section(token, context, callback, original_template)
  local value = context:lookup(token.value)

  if type(value) == "table" then
    if vim.islist(value) then
      local buffer = ""

      for _, v in ipairs(value) do
        buffer = buffer .. callback(context:push(v), self)
      end

      return buffer
    end

    return callback(context:push(value), self)
  elseif type(value) == "function" then
    ---@cast value fun(text:string, render: lustache.ScopedRender): string
    local section_text = original_template:sub(token.end_index + 1, token.closing_tag_index - 1)

    ---@type lustache.ScopedRender
    local scoped_render = function(template) return self:render(template, context) end

    return value(section_text, scoped_render) or ""
  else
    if value then return callback(context, self) end
  end

  return ""
end

---@param name string
---@param context lustache.Context
---@param callback lustache.CompiledRenderer
---@return string
function Renderer:_inverted(name, context, callback)
  local value = context:lookup(name)

  -- From the spec: inverted sections may render text once based on the
  -- inverse value of the key. That is, they will be rendered if the key
  -- doesn't exist, is false, or is an empty list.

  if value == nil or value == false or (type(value) == "table" and vim.islist(value) and #value == 0) then
    return callback(context, self)
  end

  return ""
end

---@param name string
---@param context lustache.Context
---@return string
function Renderer:_partial(name, context)
  local fn = self.partial_cache[name]

  -- check if partial cache exists
  if not fn and self.partials then
    local partial = self.partials[name]
    if not partial then return "" end

    -- compile partial and store result in cache
    fn = self:compile(partial, nil, partial)
    self.partial_cache[name] = fn
  end
  return fn and fn(context) or ""
end

---@param name string
---@param context lustache.Context
---@param escape boolean
---@return string
function Renderer:_name(name, context, escape)
  local value = context:lookup(name)

  if type(value) == "function" then value = value(context.view) end

  local str = value == nil and "" or value
  str = tostring(str)

  if escape then return (str:gsub("[&<>\"'/]", function(s) return html_escape_characters[s] end)) end

  return str
end

---Breaks up the given `template` string into a tree of token objects. If
---`tags` is given here it must be an array with two string values: the
---opening and closing tags used in the template (e.g. ["<%", "%>"]). Of
---course, the default is to use mustaches (i.e. Mustache.tags).
---@param template string
---@param tags lustache.Tags|nil
---@return lustache.Token[]|string
function Renderer:parse(template, tags)
  tags = tags or self.tags
  local tag_patterns = escape_tags(tags)
  local scanner = Scanner:new(template)
  local tokens = {} ---@type lustache.Token[] token buffer
  local spaces = {} ---@type integer[] indices of whitespace tokens on the current line
  local has_tag = false -- is there a {{tag} on the current line?
  local non_space = false -- is there a non-space char on the current line?

  -- Strips all whitespace tokens array for the current line if there was
  -- a {{#tag}} on it and otherwise only space
  local function strip_space()
    if has_tag and not non_space then
      while #spaces > 0 do
        table.remove(tokens, table.remove(spaces))
      end
    else
      spaces = {}
    end
    has_tag = false
    non_space = false
  end

  local type, value, chr ---@type string|nil, string|nil, string|nil

  while not scanner:eos() do
    local start = scanner.pos

    value = scanner:scan_until(tag_patterns[1])

    if value then
      for i = 1, #value do
        chr = value:sub(i, i)

        if chr:match "%s" then
          spaces[#spaces + 1] = #tokens + 1
        else
          non_space = true
        end

        tokens[#tokens + 1] = { type = "text", value = chr, start_index = start, end_index = start }
        start = start + 1
        if chr == "\n" then strip_space() end
      end
    end

    if not scanner:scan(tag_patterns[1]) then break end

    has_tag = true
    type = scanner:scan(patterns.tag) or "name"

    scanner:scan "%s*"

    if type == "=" then
      value = scanner:scan_until(patterns.eq)
      scanner:scan(patterns.eq)
      scanner:scan_until(tag_patterns[2])
    elseif type == "{" then
      local close_pattern = "%s*}" .. tags[2]
      value = scanner:scan_until(close_pattern)
      scanner:scan(patterns.curly)
      scanner:scan_until(tag_patterns[2])
    else
      value = scanner:scan_until(tag_patterns[2])
    end

    if not scanner:scan(tag_patterns[2]) then
      error(("Unclosed tag %s of type %s at position %s"):format(value, type, scanner.pos))
    end

    tokens[#tokens + 1] = { type = type, value = value, start_index = start, end_index = scanner.pos - 1 }
    if type == "name" or type == "{" or type == "&" then
      non_space = true --> what does this do? This stops the parser from trimming spaces inside of name and non HTML-escaped tags
    end

    if type == "=" then
      tags = vim.split(value, "%s")
      tag_patterns = escape_tags(tags)
    end
  end

  return nest_tokens(squash_tokens(tokens))
end

function Renderer:new()
  local out = {
    cache = {},
    partial_cache = {},
    tags = { "{{", "}}" },
  }
  return setmetatable(out, { __index = self })
end

return Renderer
