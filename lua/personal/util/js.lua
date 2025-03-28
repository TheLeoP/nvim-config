local api = vim.api
local ts = vim.treesitter
local ns = api.nvim_create_namespace "personal_on_key"

local M = {}

---@module 'mini'

function M.setup()
  vim.b.minisurround_config = {
    custom_surroundings = {
      ["$"] = {
        input = { "${().-()}" },
        output = { left = "${", right = "}" },
      },
    },
  }

  vim.b.miniai_config = {
    custom_textobjects = {
      ["$"] = MiniAi.gen_spec.pair("${", "}"),
    },
  }

  vim.keymap.set("i", "t", function()
    vim.schedule(function()
      local row, col = unpack(api.nvim_win_get_cursor(0))
      local start_col = math.max(col - 5, 0)
      local end_col = col
      local word = api.nvim_buf_get_text(0, row - 1, start_col, row - 1, end_col, {})[1]
      if word ~= "await" then return end

      ts.get_parser(0):parse()
      local node = ts.get_node { ignore_injections = false }
      if not node then return end

      local current = node ---@type TSNode|nil
      while current do
        if
          vim.list_contains({
            "arrow_function",
            "function_declaration",
            "function",
            "method_definition",
            "function_expression",
          }, current:type())
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
    end)

    return "t"
  end, {
    buffer = true,
    expr = true,
  })
end

return M
