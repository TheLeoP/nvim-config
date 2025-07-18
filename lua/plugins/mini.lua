local api = vim.api
local iter = vim.iter
local keymap = vim.keymap

return {
  "echasnovski/mini.nvim",

  version = false,
  dependencies = {
    "nvim-treesitter-textobjects",
    {
      "JoosepAlviste/nvim-ts-context-commentstring",
      ---@module "ts_context_commentstring"
      ---@type ts_context_commentstring.Config
      opts = {
        enable_autocmd = false,
        languages = {
          c = "// %s",
        },
      },
    },
  },
  config = function()
    local ai = require "mini.ai"
    local gen_ai_spec = require("mini.extra").gen_ai_spec

    -- TODO: support fallback to lua pattern?
    local gen_ts_spec = ai.gen_spec.treesitter
    ai.setup {
      n_lines = 500,
      custom_textobjects = {
        o = gen_ts_spec {
          a = { "@block.outer", "@conditional.outer", "@loop.outer" },
          i = { "@block.inner", "@conditional.inner", "@loop.inner" },
        },
        f = gen_ts_spec { a = "@function.outer", i = "@function.inner" },
        c = gen_ts_spec { a = "@class.outer", i = "@class.inner" },
        F = gen_ts_spec { a = "@call.outer", i = "@call.inner" },
        t = gen_ts_spec { a = "@tag.outer", i = "@tag.inner" },
        a = gen_ts_spec {
          a = { "@parameter.outer", "@attribute.outer" },
          i = { "@parameter.inner", "@attribute.inner" },
        },

        B = gen_ai_spec.buffer(),
        d = gen_ai_spec.diagnostic(),
        e = gen_ai_spec.indent(),
        i = gen_ai_spec.line(),
        u = gen_ai_spec.number(),

        g = function()
          local from = { line = 1, col = 1 }
          local to = {
            line = vim.fn.line "$",
            col = math.max(vim.fn.getline("$"):len(), 1),
          }
          return { from = from, to = to }
        end,
      },
      mappings = {
        goto_left = "g{",
        goto_right = "g}",
      },
    }

    for _, text_object in ipairs {
      { id = "f", key_goto_left = "f", key_goto_right = "F" },
      { id = "c", key_goto_left = "{", key_goto_right = "}" },
      { id = "o", key_goto_left = "o", key_goto_right = "O" },
      { id = "u", key_goto_left = "u", key_goto_right = "U" },
    } do
      for _, dir in ipairs { { b = "[", m = "prev" }, { b = "]", m = "next" } } do
        keymap.set({ "n", "x", "o" }, ("%s%s"):format(dir.b, text_object.key_goto_left), function()
          local count = vim.v.count1
          vim.cmd.normal { "m'", bang = true }
          MiniAi.move_cursor("left", "a", ("%s"):format(text_object.id), { n_times = count, search_method = dir.m })
        end, { desc = ("%s %s"):format(dir.m, text_object.id) })
        keymap.set({ "n", "x", "o" }, ("%s%s"):format(dir.b, text_object.key_goto_right), function()
          local count = vim.v.count1
          vim.cmd.normal { "m'", bang = true }
          MiniAi.move_cursor("right", "a", ("%s"):format(text_object.id), { n_times = count, search_method = dir.m })
        end, { desc = ("%s %s"):format(dir.m, text_object.id) })
      end
    end

    require("mini.align").setup {
      modifiers = {
        I = function(steps, _)
          local pattern = vim.fn.input { prompt = "Ignore pattern: " }
          if pattern == nil then return end
          table.insert(steps.pre_split, MiniAlign.gen_step.ignore_split { pattern })
        end,
      },
    }
    require("mini.move").setup {
      mappings = {
        line_right = "",
        line_left = "",
      },
    }

    ---@param ... string|number|table|
    ---@return string[]
    local function inspect_objects(...)
      local objects = {}
      -- Not using `{...}` because it removes `nil` input
      for i = 1, select("#", ...) do
        local v = select(i, ...)
        if type(v) == "table" then
          table.insert(objects, vim.inspect(v))
        else
          table.insert(objects, tostring(v))
        end
      end

      return vim.split(table.concat(objects, "\n"), "\n")
    end

    ---almost equal to default behaviour, but strings are written without quotes around them
    ---@param lines string[]
    ---@return string[]
    local function eval_lua_lines(lines)
      local lines_copy, n = vim.deepcopy(lines), #lines
      lines_copy[n] = (lines_copy[n]:find "^%s*return%s+" == nil and "return " or "") .. lines_copy[n]

      local str_to_eval = table.concat(lines_copy, "\n")

      return inspect_objects(assert(loadstring(str_to_eval))())
    end

    require("mini.operators").setup {
      sort = {
        prefix = "",
      },
      replace = {
        prefix = "<leader>r",
      },
      exchange = {
        prefix = "<leader>x",
      },
      evaluate = {
        ---@param content {lines: string[], submode: 'V'|'v'|'\22'}
        func = function(content)
          local lines, submode = content.lines, content.submode

          -- In non-blockwise mode return the result of the last line
          if submode ~= "\22" then return eval_lua_lines(lines) end

          -- In blockwise selection evaluate and return each line separately
          return vim.tbl_map(function(l)
            return eval_lua_lines({ l })[1]
          end, lines)
        end,
      },
    }
    local mini_misc = require "mini.misc"
    mini_misc.setup()
    -- ConPTY (Windows) does not support querying for bg/fg colors (OSC 11, 12)
    -- https://github.com/microsoft/terminal/issues/3718
    if vim.fn.has "win32" == 0 then mini_misc.setup_termbg_sync() end

    local surround = require "mini.surround"
    local ts_input = surround.gen_spec.input.treesitter
    surround.setup {
      mappings = {
        add = "<leader>s",
        delete = "<leader>sd",
        find = "",
        find_left = "",
        highlight = "<leader>sh",
        replace = "<leader>sc",
        update_n_lines = "<leader>sn",
      },

      n_lines = 100,

      custom_surroundings = {
        o = {
          input = surround.gen_spec.input.treesitter { outer = "@block.outer", inner = "@block.inner" },
        },
        F = {
          input = ts_input { outer = "@call.outer", inner = "@call.inner" },
          output = function()
            local fun_name = surround.user_input "Function name"
            if fun_name == nil then return end
            return { left = ("%s("):format(fun_name), right = ")" }
          end,
        },
        f = {
          input = ts_input { outer = "@function.outer", inner = "@function.inner" },
          output = function()
            local js_left = "() => {"
            local js_right = "}"
            local left = {
              lua = " function() ",
              javascript = js_left,
              typescript = js_left,
              javascriptreact = js_left,
              typescriptreact = js_left,
            }
            local right = {
              lua = " end ",
              javascript = js_right,
              typescript = js_right,
              javascriptreact = js_right,
              typescriptreact = js_right,
            }
            local ft = vim.bo.filetype
            if not left[ft] or not right[ft] then return end
            return { left = left[ft], right = right[ft] }
          end,
        },
      },
    }

    require("mini.comment").setup {
      options = {
        custom_commentstring = function()
          return require("ts_context_commentstring.internal").calculate_commentstring() or vim.bo.commentstring
        end,
      },
    }

    require("mini.hipatterns").setup {
      highlighters = {
        fixme = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
        hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
        todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
        note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
      },
    }

    require("mini.notify").setup {
      lsp_progress = {
        duration_last = 500,
      },
      window = {
        config = function()
          local has_statusline = vim.o.laststatus > 0
          local pad = vim.o.cmdheight + (has_statusline and 1 or 0)
          return { anchor = "SE", col = vim.o.columns, row = vim.o.lines - pad }
        end,
        max_width_share = 0.25,
      },
    }

    local map = require "mini.map"
    map.setup {
      integrations = {
        map.gen_integration.builtin_search(),
        map.gen_integration.diagnostic(),
        -- map.gen_integration.gitsigns(),
      },
      window = { zindex = 100 }, -- show above nvim-treesitter-context
    }

    keymap.set("n", "<leader>tm", function()
      map.toggle()
    end, { desc = "Toggle mini.map" })
    keymap.set("n", "<leader>tM", function()
      map.toggle_side()
    end, { desc = "Toggle mini.map side" })

    local splitjoin = require "mini.splitjoin"
    splitjoin.setup()

    local visits = require "mini.visits"
    visits.setup {
      list = {

        ---@param data {path:string, count:number, latest: number, labels: table<string, true>}
        filter = function(data)
          local custom_schema = data.path:match "[^:]://."
          if custom_schema and custom_schema ~= "file" then return false end
          if data.path:match ".git/COMMIT_EDITMSG$" then return false end
          return true
        end,
      },
    }
    local fzf_visits = require("personal.fzf-lua").mini_visit

    keymap.set("n", "<leader>vr", fzf_visits.recent_cwd, { desc = "Select recent (cwd)" })
    keymap.set("n", "<leader>vR", fzf_visits.recent_all, { desc = "Select recent (all)" })
    keymap.set("n", "<leader>vy", fzf_visits.frecent_cwd, { desc = "Select frecent (cwd)" })
    keymap.set("n", "<leader>vY", fzf_visits.frecent_all, { desc = "Select frecent (all)" })
    keymap.set("n", "<leader>vf", fzf_visits.frequent_cwd, { desc = "Select frequent (cwd)" })
    keymap.set("n", "<leader>vF", fzf_visits.frequent_all, { desc = "Select frequent (all)" })

    keymap.set("n", "<leader>vv", visits.add_label, { desc = "Add visit label" })
    keymap.set("n", "<leader>vV", visits.remove_label, { desc = "Remove visit label" })
    keymap.set("n", "<leader>vl", fzf_visits.select_label_cwd, { desc = "Select label (cwd)" })
    keymap.set("n", "<leader>vL", fzf_visits.select_label_all, { desc = "Select label (all)" })

    ---@module "oil"

    ---@class _oil.autocmd_opts: abolish.command_opts
    ---@field data {actions: oil.Action[],err: string}

    local group = api.nvim_create_augroup("mini.visits-oil-rename", {})
    api.nvim_create_autocmd("User", {
      pattern = "OilActionsPost",
      desc = "Rename in mini.visits index from oil move",
      group = group,
      ---@param opts _oil.autocmd_opts
      callback = function(opts)
        if opts.data.err then return end

        iter(opts.data.actions):each(
          ---@param action oil.Action
          function(action)
            if action.type ~= "move" then return end
            local posix_to_os_path = require("oil.fs").posix_to_os_path

            local _src_scheme, src_path = action.src_url:match "^(.*://)(.*)$"
            local _dest_scheme, dest_path = action.dest_url:match "^(.*://)(.*)$"
            src_path = posix_to_os_path(src_path)
            dest_path = posix_to_os_path(dest_path)

            local cur_index = visits.get_index()
            local ok, new_index = pcall(visits.rename_in_index, src_path, dest_path, cur_index)
            if not ok then return end
            visits.set_index(new_index)
          end
        )
      end,
    })

    require("mini.test").setup()
  end,
}
