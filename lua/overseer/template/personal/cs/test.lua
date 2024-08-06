return {
  name = "test",
  builder = function(params)
    if params.filter ~= "" then
      return {
        cmd = "dotnet",
        args = { "test", '--logger:"console;verbosity=detailed"', "--filter", params.filter },
      }
    end
    return {
      cmd = "dotnet",
      args = { "test", '--logger:"console;verbosity=detailed"' },
    }
  end,
  params = {
    filter = {
      type = "string",
      order = 1,
      default = "",
    },
  },
  condition = {
    filetype = "cs",
  },
}
