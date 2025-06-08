local M = {}

local api = vim.api

function M.command()
  api.nvim_input ":'[,']"
end

return M
