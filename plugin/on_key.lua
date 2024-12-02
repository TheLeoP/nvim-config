local api = vim.api
local ts = vim.treesitter
local ns = api.nvim_create_namespace "personal_on_key"

vim.on_key(function(_key, typed)
  if not vim.list_contains({ "javascript", "typescript", "javascriptreact", "typescriptreact" }, vim.bo.filetype) then
    return
  end
  if not api.nvim_get_mode().mode:match "^i" then return end
  if not (typed == "t") then return end
  local line = api.nvim_get_current_line()

  local _, col = unpack(api.nvim_win_get_cursor(0))
  local partial_line = line:sub(1, col)
  local word = partial_line:match "([^ ]*)$"
  -- not `awai` because this gets called before the `t` is added to the buffer
  if word ~= "awai" then return end

  ts.get_parser(0):parse()
  local node = ts.get_node { ignore_injections = false }
  if not node then return end

  local current = node ---@type TSNode|nil
  while current do
    if
      vim.list_contains({ "arrow_function", "function_declaration", "function", "method_definition" }, current:type())
    then
      break
    end
    current = current:parent()
  end
  if not current then return end
  local function_node = current ---@type TSNode

  local function_text = ts.get_node_text(function_node, 0)
  if vim.startswith(function_text, "async") then return end

  local start_row, start_col = function_node:start()
  vim.api.nvim_buf_set_text(0, start_row, start_col, start_row, start_col, { "async " })
end, ns)
