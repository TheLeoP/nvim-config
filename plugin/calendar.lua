local add_coq_completion = require("personal.calendar").add_coq_completion
local CalendarView = require("personal.calendar").CalendarView
local api = vim.api

add_coq_completion()

---@param opts abolish.command_opts
api.nvim_create_user_command("Cal", function(opts)
  -- TODO: take arguments
  local calendar_view = CalendarView.new()
  local today = os.date "*t" --[[@as osdate]]
  calendar_view:show(today.year, today.month)
end, { desc = "Opens multiple calendar windows to manage google calendar events", force = true })
