---@class diagnostic
---@field lnum integer
---@field filename string
---@field text string

return {
  desc = "Remove duplicate diagnostics from results",
  editable = false,
  serializable = true,
  constructor = function()
    -- You may optionally define any of the methods below
    return {
      ---@param result {diagnostics: diagnostic[]|nil}
      on_preprocess_result = function(self, task, result)
        if not result.diagnostics then return end
        ---@type table<string, true>
        local already_seen = {}
        result.diagnostics = vim.tbl_filter(function(diagnostic)
          local key = ("%s:%s"):format(diagnostic.filename, diagnostic.lnum)
          if already_seen[key] then
            return false
          else
            already_seen[key] = true
            return true
          end
        end, result.diagnostics)
      end,
    }
  end,
}
