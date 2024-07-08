local api = vim.api
local ts = vim.treesitter

local function get_ts_nodes()
  if not pcall(ts.get_parser) then return end
  local wininfo = vim.fn.getwininfo(api.nvim_get_current_win())[1]
  -- Get current node, and then its parent nodes recursively.
  local cur_node = ts.get_node()
  if not cur_node then return end

  local nodes = { cur_node }
  local parent = cur_node:parent()
  while parent do
    table.insert(nodes, parent)
    parent = parent:parent()
  end

  -- Create Leap targets from TS nodes.
  local targets = {}
  local startline, startcol ---@type integer, integer
  local endline, endcol ---@type integer, integer
  for _, node in ipairs(nodes) do
    startline, startcol, endline, endcol = node:range() -- (0,0)
    local startpos = { startline + 1, startcol + 1 }
    local endpos = { endline + 1, endcol + 1 }
    -- Add both ends of the node.
    if startline + 1 >= wininfo.topline then table.insert(targets, { pos = startpos, altpos = endpos }) end
    if endline + 1 <= wininfo.botline then table.insert(targets, { pos = endpos, altpos = startpos }) end
  end
  if #targets >= 1 then return targets end
end

local function select_node_range(target)
  local mode = api.nvim_get_mode().mode

  -- Force going back to Normal from Visual mode.
  if not mode:match "no?" then vim.cmd("normal! " .. mode) end
  vim.fn.cursor(unpack(target.pos))
  local v = mode:match "V" and "V" or mode:match "" and "" or "v"
  vim.cmd("normal! " .. v)
  vim.fn.cursor(unpack(target.altpos))
end

local function leap_ts()
  require("leap").leap {
    target_windows = { api.nvim_get_current_win() },
    targets = get_ts_nodes,
    action = select_node_range,
  }
end

return {
  {
    "ggandor/leap.nvim",
    dependencies = { "tpope/vim-repeat" },
    config = function()
      vim.keymap.set({ "n", "x", "o" }, "s", "<Plug>(leap-forward)")
      vim.keymap.set({ "n", "x", "o" }, "S", "<Plug>(leap-backward)")
      vim.keymap.set({ "x", "o" }, "gs", leap_ts)
    end,
  },
  {
    "ggandor/leap-spooky.nvim",
    config = function()
      vim.keymap.set({ "x", "o" }, "ir", function()
        local ok, char = pcall(vim.fn.getcharstr)
        if not ok or char == "\27" or not char then return end

        -- requires mini.ai l mapping
        if char == "r" then char = "l" end

        require("leap").leap {
          target_windows = { api.nvim_get_current_win() },
          action = require("leap-spooky").spooky_action(
            function() return "vi" .. char end,
            { keeppos = true, on_exit = false }
          ),
        }
      end)

      vim.keymap.set({ "x", "o" }, "ar", function()
        local ok, char = pcall(vim.fn.getcharstr)
        if not ok or char == "\27" or not char then return end

        -- requires mini.ai L mapping
        if char == "r" then char = "L" end

        require("leap").leap {
          target_windows = { api.nvim_get_current_win() },
          action = require("leap-spooky").spooky_action(
            function() return "va" .. char end,
            { keeppos = true, on_exit = false }
          ),
        }
      end)
    end,
    dependencies = { "leap.nvim", "mini.nvim" },
  },
}
