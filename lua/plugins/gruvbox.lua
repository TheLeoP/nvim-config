return {
  "ellisonleao/gruvbox.nvim",
  priority = 1000,
  config = function()
    require("gruvbox").setup {
      overrides = {
        DiagnosticHint = { link = "GruvboxFg2" },
        DiagnosticSignHint = { link = "GruvboxFg2" },
        DiagnosticFloatingHint = { link = "GruvboxFg2" },
        DiagnosticUnderlineHint = { undercurl = true, sp = "#d5c4a1" },
        DiagnosticVirtualTextHint = { link = "GruvboxFg2" },

        LspReferenceText = { underline = true, sp = "#d5c4a1" },
        LspReferenceRead = { underline = true, sp = "#d5c4a1" },
        LspReferenceWrite = { underline = true, sp = "#fe8019" },

        FloatBorder = { link = "NormalFloat" },

        FoldColumn = { link = "Normal" },
        Folded = { bg = "#1d2021" },
        SignColumn = { link = "Normal" },

        debugPC = { bg = "#1d2021" },

        TreesitterContextBottom = { underline = true, sp = "#665c54" },

        FzfLuaSearch = { link = "Visual" },
        -- fzf-lua uses this by default
        TelescopeSelection = { link = "Visual" },

        DapUIStop = { fg = "#fb4934", bg = "#282828" },
        DapUIStopNC = { fg = "#fb4934", bg = "#3c3836" },
        DapUIPlayPause = { fg = "#b8bb26", bg = "#282828" },
        DapUIPlayPauseNC = { fg = "#b8bb26", bg = "#3c3836" },
        DapUIRestart = { fg = "#b8bb26", bg = "#282828" },
        DapUIRestartNC = { fg = "#b8bb26", bg = "#3c3836" },
        DapUIStepOver = { fg = "#83a598", bg = "#282828" },
        DapUIStepOverNC = { fg = "#83a598", bg = "#3c3836" },
        DapUIStepInto = { fg = "#83a598", bg = "#282828" },
        DapUIStepIntoNC = { fg = "#83a598", bg = "#3c3836" },
        DapUIStepBack = { fg = "#83a598", bg = "#282828" },
        DapUIStepBackNC = { fg = "#83a598", bg = "#3c3836" },
        DapUIStepOut = { fg = "#83a598", bg = "#282828" },
        DapUIStepOutNC = { fg = "#83a598", bg = "#3c3836" },

        ["@lsp.type.interface"] = { link = "@type" },
        ["@lsp.type.struct"] = { link = "@structure" },

        ["@lsp.mod.readonly"] = { link = "@constant" },
        ["@lsp.mod.defaultLibrary"] = { link = "@function.builtin" },

        ["@lsp.typemod.function.defaultLibrary"] = { link = "@function.builtin" },
        ["@lsp.typemod.variable.defaultLibrary"] = { link = "@variable.builtin" },
        ["@lsp.typemod.variable.readonly"] = { link = "@constant" },

        -- personal preferences
        ["@lsp.type.string"] = { link = "None" },
      },
      italic = {
        strings = false,
        comments = true,
        operators = false,
        folds = false,
        emphasis = false,
      },
      inverse = true,
    }
    vim.cmd.colorscheme "gruvbox"
  end,
}
