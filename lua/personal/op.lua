local M = {}

local api = vim.api

function M.dot() api.nvim_feedkeys(":'[,']", "n", false) end

function M.noop() end

return M
