local M = {}

local api = vim.api

function M.dot()
  api.nvim_feedkeys(":'[,']", "n", false)
end

return M
