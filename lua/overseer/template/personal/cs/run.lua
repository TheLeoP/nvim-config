return {
  name = "run",
  builder = function()
    return {
      cmd = "dotnet",
      args = { "run" },
    }
  end,
  condition = {
    filetype = "cs",
  },
}
