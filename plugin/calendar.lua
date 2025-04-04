local CalendarView = require("personal.calendar").CalendarView
local api = vim.api

local calendar_view = CalendarView.new()

---@param opts abolish.command_opts
api.nvim_create_user_command("Cal", function(opts)
  local today = os.date "*t" --[[@as osdate]]
  local year = tonumber(opts.fargs[1] or today.year) --[[@as integer]]
  local month = tonumber(opts.fargs[2] or today.month) --[[@as integer]]
  calendar_view:show(year, month)
end, {
  desc = "Opens multiple calendar windows to manage google calendar events",
  nargs = "*",
  force = true,
})
