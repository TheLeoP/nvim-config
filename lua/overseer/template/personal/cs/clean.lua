return {
  name = "clean",
  builder = function()
    return {
      cmd = "dotnet",
      args = { "clean" },
    }
  end,
  condition = {
    filetype = "cs",
  },
}
