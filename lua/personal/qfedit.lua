local M = {}

local api = vim.api

local lines = {} ---@type table<integer, string[]>

local last_id = 0

local function id()
  last_id = last_id + 1
  return last_id
end

---@param bufnr integer
local function set_options(bufnr)
  if not vim.b[bufnr].qfedit_is_locked then vim.opt_local.modifiable = true end
  vim.opt_local.swapfile = false
  if api.nvim_buf_get_name(bufnr) == "" then api.nvim_buf_set_name(bufnr, ("qfedit://%d"):format(id())) end
end

local function lock_buffer(bufnr)
  vim.b[bufnr].qfedit_is_locked = true
  if vim.api.nvim_buf_is_loaded(bufnr) then vim.bo[bufnr].modifiable = false end
end

local function unlock_buffer(bufnr)
  vim.b[bufnr].qfedit_is_locked = false
  if vim.api.nvim_buf_is_loaded(bufnr) then vim.bo[bufnr].modifiable = true end
end

local function is_loclist()
  local winnr = api.nvim_get_current_win()
  local wininfo = vim.fn.getwininfo(winnr)[1]
  return wininfo.loclist == 1
end

---@param bufnr integer
function M.start(bufnr)
  if vim.opt_local.buftype:get() ~= "quickfix" then return end
  set_options(bufnr)
  if vim.b[bufnr].qfedit_enabled then return end
  vim.b[bufnr].qfedit_enabled = true

  local augroup = api.nvim_create_augroup("qfedit", {})
  api.nvim_create_autocmd("BufWriteCmd", {
    group = augroup,
    buffer = bufnr,
    callback = function()
      if vim.opt_local.modified:get() then
        lock_buffer(bufnr)
        local winnr = api.nvim_get_current_win()

        local view = vim.fn.winsaveview()

        local removed_lines_index = {} ---@type integer[]
        local current_lines = api.nvim_buf_get_lines(bufnr, 0, -1, true)
        for i, old_line in ipairs(lines[bufnr]) do
          if not vim.list_contains(current_lines, old_line) then table.insert(removed_lines_index, i) end
        end

        local new_qf = {}
        if #removed_lines_index > 0 then
          local current_qf = is_loclist() and vim.fn.getloclist(winnr) or vim.fn.getqflist()
          local current_qf_info = is_loclist() and vim.fn.getloclist(winnr, { title = 0 })
            or vim.fn.getqflist { title = 0 }
          local current_title = current_qf_info.title

          for i, item in ipairs(current_qf) do
            if not vim.list_contains(removed_lines_index, i) then table.insert(new_qf, item) end
          end

          lines[bufnr] = current_lines
          if is_loclist() then
            vim.fn.setloclist(winnr, {}, " ", { title = current_title, items = new_qf })
          else
            vim.fn.setqflist({}, " ", { title = current_title, items = new_qf })
          end
        end

        vim.fn.winrestview(view)
        unlock_buffer(bufnr)
      end

      vim.opt_local.modified = false
    end,
  })
  lines[bufnr] = api.nvim_buf_get_lines(bufnr, 0, -1, true)
end

return M
