local join = require "personal.join"
local api = vim.api

api.nvim_create_user_command("Join", function() join.write_buffer(0) end, {})
