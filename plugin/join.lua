local join = require "personal.join"
local api = vim.api
local iter = vim.iter

---@param opts abolish.command_opts
api.nvim_create_user_command("Join", function(opts)
  if opts.args == "" then
    join.write_buffer(0)
    return
  elseif #opts.fargs == 1 and opts.fargs[1] == "auth" then
    join.open_app "Authenticator"
  end
end, {
  desc = "Join command entrypoint",
  ---@param arg_lead string
  ---@param _cmd_line string
  ---@param _cursor_pos integer
  ---@return string[]
  complete = function(arg_lead, _cmd_line, _cursor_pos)
    return iter({ "auth" })
      :filter(function(subcommand)
        return vim.startswith(subcommand, arg_lead)
      end)
      :totable()
  end,
  nargs = "*",
  force = true,
})
