---@class coq_args
---@field pos {[1]: integer, [2]:integer}
---@field line string

---@class coq_callback_args
---@field isIncomplete boolean
---@field items vim.lsp.CompletionResult

---@class coq_source
---@field name string
---@field fn fun(args: coq_args, callback: fun(args?: coq_callback_args)): fun()|nil

---@alias coq_sources table<integer, coq_source>

---@param map coq_sources
local function new_uid(map)
  local key ---@type integer|nil
  while true do
    if not key or map[key] then
      key = math.floor(math.random() * 10000)
    else
      return key
    end
  end
end

return {
  "ms-jpq/coq_nvim",
  branch = "coq",
  init = function()
    vim.opt.completeopt = { "menuone", "noselect", "noinsert" }
    vim.opt.showmode = false

    vim.g.coq_settings = {
      auto_start = "shut-up",
      keymap = {
        recommended = false,
        jump_to_mark = "<m-,>",
        bigger_preview = "",
      },
      clients = {
        snippets = {
          warn = {},
        },
        paths = {
          path_seps = {
            "/",
          },
        },
        buffers = {
          match_syms = false,
        },
        third_party = {
          enabled = true,
        },
        lsp = {
          weight_adjust = 1,
        },
      },
      display = {
        preview = {
          border = { "", "", "", " ", "", "", "", " " },
        },
        ghost_text = {
          enabled = true,
        },
        pum = {
          fast_close = false,
        },
        statusline = {
          helo = false,
        },
      },
      match = {
        unifying_chars = {
          "-",
          "_",
        },
      },
      limits = {
        completion_manual_timeout = 1.0,
      },
    }
  end,
  config = function()
    vim.keymap.set("i", "<BS>", function()
      if vim.fn.pumvisible() == 1 then
        return "<C-e><BS>"
      else
        return "<BS>"
      end
    end, { expr = true, silent = true })

    vim.keymap.set("i", "<CR>", function()
      if vim.fn.pumvisible() == 1 then
        if vim.fn.complete_info().selected == -1 then
          return "<C-e><CR>"
        else
          return "<C-y>"
        end
      else
        return "<CR>"
      end
    end, { expr = true, silent = true })

    vim.keymap.set("i", "<Tab>", function()
      if vim.fn.pumvisible() == 1 then
        return "<down>"
      else
        return "<Tab>"
      end
    end, { expr = true, silent = true })

    vim.keymap.set("i", "<s-tab>", function()
      if vim.fn.pumvisible() == 1 then
        return "<up>"
      else
        return "<s-tab>"
      end
    end, { expr = true, silent = true })

    COQsources = COQsources or {} ---@type coq_sources

    COQsources[new_uid(COQsources)] = {
      name = "Q",
      fn = function(args, callback)
        if vim.bo.filetype ~= "query" then return callback() end
        local row, col = unpack(args.pos) ---@type integer, integer

        local start_col = vim.treesitter.query.omnifunc(1, "")
        ---@cast start_col integer

        if start_col == -2 or start_col == -3 then return callback() end

        local cword = vim.api.nvim_buf_get_text(0, row, start_col, row, col, {})[1]
        local maybe_matches = vim.treesitter.query.omnifunc(0, cword)

        if maybe_matches == -2 or maybe_matches == -3 then return callback() end ---@cast maybe_matches -integer

        local items = vim ---@type vim.lsp.CompletionResult
          .iter(maybe_matches.words)
          :map(
            function(word)
              return {
                label = word,
                insertText = word,
              }
            end
          )
          :totable()

        callback {
          isIncomplete = false,
          items = items,
        }
      end,
    }

    COQsources[new_uid(COQsources)] = {
      name = "DAP",
      fn = function(args, callback)
        if vim.bo.filetype ~= "dap-repl" then return callback() end
        local row, col = unpack(args.pos) ---@type integer, integer

        local start_col = require("dap.repl").omnifunc(1, "")
        ---@cast start_col integer

        if start_col == -2 or start_col == -3 then return callback() end

        if start_col < 0 then start_col = vim.api.nvim_win_get_cursor(0)[2] end

        local cword = vim.api.nvim_buf_get_text(0, row, start_col, row, col, {})[1]
        local maybe_matches = require("dap.repl").omnifunc(0, cword)

        if maybe_matches == -2 or maybe_matches == -3 then return callback() end ---@cast maybe_matches -integer

        local items = vim ---@type vim.lsp.CompletionResult
          .iter(maybe_matches)
          :map(
            function(word)
              return {
                label = word,
                insertText = word,
              }
            end
          )
          :totable()

        callback {
          isIncomplete = false,
          items = items,
        }
      end,
    }

    COQsources[new_uid(COQsources)] = {
      name = "DB",
      fn = function(args, callback)
        if vim.bo.filetype ~= "sql" and vim.bo.filetype ~= "psql" then return callback() end
        local row, col = unpack(args.pos) ---@type integer, integer

        local start_col = vim.fn["vim_dadbod_completion#omni"](1, "")
        ---@cast start_col integer

        if start_col == -2 or start_col == -3 then return callback() end

        if start_col < 0 then start_col = vim.api.nvim_win_get_cursor(0)[2] end

        local cword = vim.api.nvim_buf_get_text(0, row, start_col, row, col, {})[1]
        local maybe_matches = vim.fn["vim_dadbod_completion#omni"](0, cword)

        if maybe_matches == -2 or maybe_matches == -3 then return callback() end ---@cast maybe_matches -integer

        local items = vim ---@type vim.lsp.CompletionResult
          .iter(maybe_matches)
          :map(
            function(match)
              return {
                label = match.abbr,
                insertText = match.word,
                detail = match.info,
              }
            end
          )
          :totable()

        callback {
          isIncomplete = false,
          items = items,
        }
      end,
    }
  end,
}
