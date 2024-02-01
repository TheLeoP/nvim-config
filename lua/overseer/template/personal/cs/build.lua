return {
  name = "build",
  builder = function()
    return {
      cmd = "dotnet",
      args = { "build" },
    }
  end,
  condition = {
    filetype = "cs",
  },
}
