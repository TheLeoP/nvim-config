local M = {}

local api = vim.api

function M.dot() api.nvim_feedkeys(":'[,']", "n", false) end

function M.noop() end

function M.coq_repeat() COQ.Repeat() end

return M
