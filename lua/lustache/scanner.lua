---@class luastache.Scanner
---@field tail string
---@field str string
---@field pos integer
local Scanner = {}

---Returns `true` if the tail is empty (end of string).
---@return boolean
function Scanner:eos() return self.tail == "" end

---Tries to match the given lua pattern at the current position.
---Returns the matched text if it can match, `nil` otherwise.
---@param pattern string
---@return string|nil
function Scanner:scan(pattern)
  local match = self.tail:match(pattern)

  if not match or self.tail:find(pattern) ~= 1 then return end

  self.tail = self.tail:sub(#match + 1)
  self.pos = self.pos + #match

  return match
end

---Skips all text until the given lua pattern can be matched. Returns
---the skipped string, which is the entire tail of this scanner if no match
---can be made.
---@param pattern string
---@return string|nil
function Scanner:scan_until(pattern)
  local pos = self.tail:find(pattern)

  if pos == 1 then return end

  local match ---@type string|nil

  if pos == nil then
    match = self.tail
    self.tail = ""
    self.pos = self.pos + #self.tail
  else
    match = self.tail:sub(1, pos - 1)
    self.tail = self.tail:sub(pos)
    self.pos = self.pos + #match
  end

  return match
end

---@param str string
---@return luastache.Scanner
function Scanner:new(str)
  local out = {
    str = str,
    tail = str,
    pos = 1,
  }
  return setmetatable(out, { __index = self })
end

return Scanner
