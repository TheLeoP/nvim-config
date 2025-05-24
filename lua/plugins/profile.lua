local should_profile = vim.env.NVIM_PROFILE

local function toggle_profile()
  local prof = require "profile"
  if prof.is_recording() then
    prof.stop()
    vim.ui.input({ prompt = "Save profile to:", completion = "file", default = "profile.json" }, function(filename)
      if filename then
        prof.export(filename)
        vim.notify(("Wrote %s"):format(filename))
      end
    end)
  else
    vim.notify "Starting recording"
    prof.start "*"
  end
end

return {
  "stevearc/profile.nvim",
  config = function()
    if should_profile then
      require("profile").instrument_autocmds()
      if should_profile:lower():match "^start" then
        require("profile").start "*"
      else
        require("profile").instrument "*"
      end

      vim.keymap.set("n", "<f4>", toggle_profile)
    end
  end,
}
