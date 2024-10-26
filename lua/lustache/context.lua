---@alias lustache.ScopedRender fun(template: string): string

---@alias lustache.Value string|string[]|fun(context: lustache.Context): string|fun(text:string, render: lustache.ScopedRender): string|

---@alias lustache.View table<string, lustache.Value>

---@alias lustache.Partial table<string, string> name -> text

---@class lustache.Context
---@field cache table<string, lustache.Value|lustache.View>
---@field view lustache.View
---@field parent lustache.Context
local Context = {}
Context.__index = Context

function Context:clear_cache() self.cache = {} end

---@return lustache.Context
function Context:push(view) return self:new(view, self) end

---@param name string
---@return lustache.Value|lustache.View
function Context:lookup(name)
  local value = self.cache[name] ---@type lustache.Value|lustache.View
  if value then return value end

  if name == "." then
    self.cache[name] = self.view
    return self.view
  end

  local context = self
  while context do
    if name:find "%." > 0 then
      local current = context.view ---@type lustache.Value|lustache.View
      for current_name in vim.gsplit(name, "%.") do
        current = current[current_name]
      end
      value = current
    else
      value = context.view[name]
    end

    if value then break end
    context = context.parent
  end

  self.cache[name] = value

  return value
end

---@param view lustache.View
---@param parent lustache.Context|nil
---@return lustache.Context
function Context:new(view, parent)
  local out = {
    view = view,
    parent = parent,
    cache = {},
  }
  return setmetatable(out, Context)
end

return Context
