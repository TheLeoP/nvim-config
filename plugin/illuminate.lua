vim.pack.add {
  {
    src = "https://github.com/TheLeoP/vim-illuminate",
    version = "leo",
  },
}

require("illuminate").configure {
  modes_denylist = {
    "i",
    "ic",
    "ix",

    "v",
    "V",
    "\22",

    "R",
    "Rc",
    "Rx",
    "Rv",
    "Rvc",
    "Rvx",

    "c",
    "cv",

    "r",
    "rm",
    "r?",
    "t",
  },
  filetypes_denylist = {
    "",
  },
  min_count_to_highlight = 2,
}
