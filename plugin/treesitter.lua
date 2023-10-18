local force = true
vim.treesitter.query.add_directive(
  "offset-lua-match!",
  ---@param match table<string, TSNode>
  ---@param pattern string
  ---@param bufnr integer
  ---@param predicate string[]
  ---@param metadata table<string, {range: integer[]}>
  function(match, pattern, bufnr, predicate, metadata)
    local capture_id = predicate[2]
    if not metadata[capture_id] then metadata[capture_id] = {} end

    local lua_pattern = predicate[3]

    local node = match[capture_id]
    local text = vim.treesitter.get_node_text(node, bufnr)
    local start, end_ = text:find(lua_pattern)

    if not start then return end

    local range = metadata[capture_id].range or { node:range() }

    local start_row_offset = predicate[4] and tonumber(predicate[4]) or 0
    local start_col_offset = predicate[5] and tonumber(predicate[5]) or 0
    local end_row_offset = predicate[6] and tonumber(predicate[6]) or 0
    local end_col_offset = predicate[7] and tonumber(predicate[7]) or 0

    range[1] = range[1] + start_row_offset
    range[3] = range[3] + end_row_offset

    range[4] = range[2] + end_ + end_col_offset
    range[2] = range[2] + start - 1 + start_col_offset

    -- If this produces an invalid range, we just skip it.
    if range[1] < range[3] or (range[1] == range[3] and range[2] <= range[4]) then
      metadata[capture_id].range = range
    end
  end,
  force
)
