-- TODO: create a PR to add to Neovim
-- TODO: support prompts spanning multiple lines
local M = {}

---@param buf integer
---@param cursor {[1]: integer, [2]: integer}
local function set_term_cursor(buf, cursor)
  local bufinfo = M.buffers[buf]
  local prompt_start = bufinfo.prompt_cursor[2]
  local line = vim.api.nvim_buf_get_lines(buf, cursor[1] - 1, cursor[1], true)[1]
  local cursor_end_index = vim.str_utfindex(line, "utf-32", cursor[2], true)
  local p = vim.keycode(bufinfo.term_keys.goto_line_start)
    .. vim.keycode(bufinfo.term_keys.forward_char):rep(cursor_end_index - prompt_start)
  vim.fn.chansend(vim.bo.channel, p)
end

---@param buf integer
---@param chan integer
---@param line string
local function update_line(buf, chan, line)
  local bufinfo = M.buffers[buf]
  local cursor = vim.api.nvim_win_get_cursor(0)
  if not bufinfo.prompt_cursor or cursor[1] ~= bufinfo.prompt_cursor[1] then return end

  vim.fn.chansend(chan, vim.keycode(bufinfo.term_keys.clear_current_line))
  local prompt_start = bufinfo.prompt_cursor[2]
  local prompt_start_byte_index = vim.str_byteindex(line, "utf-32", prompt_start)
  vim.fn.chansend(chan, line:sub(prompt_start_byte_index + 1))

  M.buffers[buf].waiting = true
  vim.defer_fn(function()
    M.buffers[buf].waiting = false
  end, M.wait_for_keys_delay)
end

---@class editable_term.Prompt
---@field term_keys? editable_term.TermKeys

---@class editable_term.TermKeys
---@field clear_current_line string
---@field forward_char string
---@field goto_line_start string
---@field goto_line_end string

---@class editable_term.Config
---@field term_keys? editable_term.TermKeys
---@field wait_for_keys_delay? integer

---@class editable_term.BufInfo
---@field term_keys? editable_term.TermKeys
---@field waiting? boolean
---@field prompt_cursor? {[1]: integer, [2]: integer}

---@type {[integer]: editable_term.BufInfo}
M.buffers = {}
M.wait_for_keys_delay = 50

---@param config editable_term.Config?
M.setup = function(config)
  config = config or {}

  local term_keys = config.term_keys
    or {
      goto_line_start = "<c-a>",
      goto_line_end = "<c-e>",
      clear_current_line = "<c-u>",
      forward_char = "<c-f>",
    }
  if config.wait_for_keys_delay then M.wait_for_keys_delay = config.wait_for_keys_delay end

  vim.api.nvim_create_autocmd("TermOpen", {
    group = vim.api.nvim_create_augroup("editable-term", { clear = true }),
    callback = function(args)
      local editgroup = vim.api.nvim_create_augroup("editable-term-text-change" .. args.buf, { clear = true })
      M.buffers[args.buf] = { term_keys = term_keys }

      vim.keymap.set("n", "A", function()
        local bufinfo = M.buffers[args.buf]
        if bufinfo.prompt_cursor then
          local cursor_row, cursor_col = unpack(bufinfo.prompt_cursor)
          local line = vim.api.nvim_buf_get_lines(args.buf, cursor_row - 1, cursor_row, true)[1]
          line = line:sub(cursor_col)
          local start = line:find "%s*$"
          local p = vim.keycode(bufinfo.term_keys.goto_line_start)
            .. vim.keycode(bufinfo.term_keys.forward_char):rep(start - 2)
          vim.fn.chansend(vim.bo.channel, p)
        end
        vim.cmd.startinsert()
      end, { buffer = args.buf })

      vim.keymap.set("n", "I", function()
        local bufinfo = M.buffers[args.buf]
        if bufinfo.prompt_cursor then
          local cursor_row, cursor_col = unpack(bufinfo.prompt_cursor)
          local line = vim.api.nvim_buf_get_lines(args.buf, cursor_row - 1, cursor_row, false)[1]
          line = line:sub(cursor_col)
          local _, end_ = line:find "[^%s]"
          local p = vim.keycode(bufinfo.term_keys.goto_line_start)
            .. vim.keycode(bufinfo.term_keys.forward_char):rep(end_ - 2)
          vim.fn.chansend(vim.bo.channel, p)
        end
        vim.cmd.startinsert()
      end, { buffer = args.buf })

      vim.keymap.set("n", "i", function()
        local bufinfo = M.buffers[args.buf]
        local cursor = vim.api.nvim_win_get_cursor(0)
        if bufinfo.prompt_cursor then
          if cursor[1] == bufinfo.prompt_cursor[1] then
            set_term_cursor(args.buf, cursor)
          else
            vim.fn.chansend(vim.bo.channel, vim.keycode(bufinfo.term_keys.goto_line_end))
          end
        end
        vim.cmd.startinsert()
      end, { buffer = args.buf })

      vim.keymap.set("n", "a", function()
        local bufinfo = M.buffers[args.buf]
        if bufinfo.prompt_cursor then
          local cursor = vim.api.nvim_win_get_cursor(0)
          if cursor[1] == bufinfo.prompt_cursor[1] then
            cursor[2] = cursor[2] + 1
            set_term_cursor(args.buf, cursor)
          else
            vim.fn.chansend(vim.bo.channel, vim.keycode(bufinfo.term_keys.goto_line_end))
          end
        end
        vim.cmd.startinsert()
      end, { buffer = args.buf })

      vim.keymap.set("n", "dd", function()
        local bufinfo = M.buffers[args.buf]
        vim.fn.chansend(
          vim.bo.channel,
          vim.keycode(bufinfo.term_keys.clear_current_line .. bufinfo.term_keys.goto_line_start)
        )
        local cursor = vim.api.nvim_win_get_cursor(0)
        cursor[2] = 0
        set_term_cursor(args.buf, cursor)
      end, { buffer = args.buf })

      vim.keymap.set("n", "cc", function()
        local bufinfo = M.buffers[args.buf]
        vim.fn.chansend(
          vim.bo.channel,
          vim.keycode(bufinfo.term_keys.clear_current_line .. bufinfo.term_keys.goto_line_start)
        )
        local cursor = vim.api.nvim_win_get_cursor(0)
        cursor[2] = 0
        set_term_cursor(args.buf, cursor)
        vim.cmd.startinsert()
      end, { buffer = args.buf })

      vim.api.nvim_create_autocmd("TextYankPost", {
        group = editgroup,
        buffer = args.buf,
        callback = function(args2)
          local start_point = vim.api.nvim_buf_get_mark(args2.buf, "[")
          local end_point = vim.api.nvim_buf_get_mark(args2.buf, "]")

          if start_point[1] ~= end_point[1] then
            vim.fn.chansend(vim.bo.channel, vim.keycode "<C-C>")
          elseif vim.v.event.operator == "c" then
            local line = vim.api.nvim_buf_get_lines(args2.buf, start_point[1] - 1, start_point[1], true)[1]
            start_point[2] = start_point[2] + vim.str_utf_start(line, start_point[2] + 1)
            end_point[2] = end_point[2] + vim.str_utf_end(line, end_point[2] + 1) + 1 + 1
            line = line:sub(1, start_point[2]) .. line:sub(end_point[2])
            update_line(args2.buf, vim.bo.channel, line)

            -- NOTE: this is an empty region
            if start_point[1] == end_point[1] and end_point[2] < start_point[2] then
              start_point[2] = start_point[2] - 1
            end
            set_term_cursor(args2.buf, start_point)
          end
        end,
      })

      vim.api.nvim_create_autocmd("TextChanged", {
        buffer = args.buf,
        group = editgroup,
        callback = function(args2)
          local bufinfo = M.buffers[args2.buf]
          if bufinfo.waiting then return end
          if not bufinfo.prompt_cursor then return end

          local cursor_row = unpack(bufinfo.prompt_cursor)
          local line = vim.api.nvim_buf_get_lines(args.buf, cursor_row - 1, cursor_row, true)[1]
          update_line(args2.buf, vim.bo.channel, line)
        end,
      })

      vim.api.nvim_create_autocmd("TermRequest", {
        group = editgroup,
        buffer = args.buf,
        callback = function(args2)
          if not string.match(args2.data.sequence, "^\027]133;B") then return end

          M.buffers[args2.buf].prompt_cursor = args2.data.cursor
        end,
      })

      vim.api.nvim_create_autocmd("BufDelete", {
        group = editgroup,
        buffer = args.buf,
        callback = function()
          vim.api.nvim_del_augroup_by_id(editgroup)
        end,
      })

      vim.api.nvim_create_autocmd("CursorMoved", {
        group = editgroup,
        buffer = args.buf,
        callback = function(args2)
          local cursor = vim.api.nvim_win_get_cursor(0)
          local bufinfo = M.buffers[args2.buf]
          vim.bo.modifiable = bufinfo.prompt_cursor ~= nil and cursor[1] == bufinfo.prompt_cursor[1]
        end,
      })
    end,
  })
end

return M
