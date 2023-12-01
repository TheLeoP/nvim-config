local M = {}

M.char = ""

function M.opertator_func()
  local ok, char = pcall(vim.fn.getcharstr)
  vim.cmd [[echo '' | redraw]]

  if not ok or char == "\27" then return end
  M.char = char

  vim.o.operatorfunc = "v:lua.require'personal.abolish'.coerce"
  return "g@"
end

---@param type "line"|"char"|"block"
function M.coerce(type)
  local cursor_location = vim.api.nvim_win_get_cursor(0)
  local c = vim.v.count1 ---@type integer
  while c > 0 do
    c = c - 1

    ---@type integer, integer
    local start_row, start_col = unpack(vim.api.nvim_buf_get_mark(0, "["))
    ---@type integer, integer
    local end_row, end_col = unpack(vim.api.nvim_buf_get_mark(0, "]"))

    if type == "line" then
      local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, true)
      for i, line in ipairs(lines) do
        local coerced_line = M.coercions[M.char](line)
        if line ~= coerced_line then
          vim.api.nvim_buf_set_lines(0, start_row - 1 + i - 1, start_row - 1 + i, true, { coerced_line })
        end
      end
    elseif type == "block" then
      local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, true)
      for i, line in ipairs(lines) do
        local text = line:sub(start_col + 1, end_col + 1)
        local coerced_text = M.coercions[M.char](text)
        if text ~= coerced_text then
          vim.api.nvim_buf_set_text(
            0,
            start_row - 1 + i - 1,
            start_col,
            start_row - 1 + i - 1,
            end_col + 1,
            { coerced_text }
          )
        end
      end
    else
      local lines = vim.api.nvim_buf_get_text(0, start_row - 1, start_col, end_row - 1, end_col + 1, {})
      local text = table.concat(lines, "\n")
      local coerced_text = M.coercions[M.char](text)
      if text ~= coerced_text then
        vim.api.nvim_buf_set_text(
          0,
          start_row - 1,
          start_col,
          end_row - 1,
          end_col + 1,
          vim.split(coerced_text, "\n", { trimempty = true })
        )
      end
    end
  end
  vim.api.nvim_win_set_cursor(0, cursor_location)
end

---@type table<string, string>
local abolish_last_dict

---@class abolish.command_opts
---@field name string Command name
---@field args string The args passed to the command, if any
---@field fargs string[] The args split by unescaped whitespace (when more than one argument is allowed), if any
---@field nargs number Number of arguments
---@field bang boolean "true" if the command was executed with a ! modifier
---@field line1 number The starting line of the command range
---@field line2 number The final line of the command range
---@field range number The number of items in the command range: 0, 1, or 2
---@field count number Any count supplied
---@field reg string The optional register, if specified
---@field mods string Command modifiers, if any
---@field smods string[] Command modifiers in a structured format. Has the same structure as the "mods" key of nvim_parse_cmd()

---@param flags string|table<string, any>
local function normalize_options(flags)
  ---@type table<string, any>, string
  local opts
  if type(flags) == "table" then
    opts = flags
    flags = flags.flags --[[@as string]]
  else
    opts = {}
  end

  local w_flag = vim.regex "w" --[[@ as vim.regex]]
  local v_flag = vim.regex "v" --[[@ as vim.regex]]
  if w_flag:match_str(flags) then
    opts.boundaries = 2
  elseif v_flag:match_str(flags) then
    opts.boundaries = 1
  elseif not opts.boundaries then
    opts.boundaries = 0
  end

  local i_flag = vim.regex "I" --[[@ as vim.regex]]
  opts.case = opts.case or true
  opts.case = not i_flag:match_str(flags) and opts.case or false
  opts.flags = vim.fn.substitute(flags, [=[\C[Ivwi]]=], "", "g")
  return opts
end

---@param p abolish.parsed_input
local function expand_braces(p)
  ---@type table<string, string>
  local out = {}
  local string = p.string or { before = "", fragments = {}, after = "" }

  local total = math.max(#p.pattern.fragments, #string.fragments)

  if total == 0 then
    out[p.pattern.before .. p.pattern.after] = string.before .. string.after
    return out
  end

  for i = 1, total do
    out[p.pattern.before .. p.pattern.fragments[i] .. p.pattern.after] = string.before
      .. string.fragments[i]
      .. string.after
  end
  return out
end

---@param word string
---@return string
function M.camelcase(word)
  word = assert(vim.fn.substitute(word, "-", "_", "g"))
  local regex_ = vim.regex "_" --[[@as vim.regex]]
  local regex_l = vim.regex [[\l]] --[[@as vim.regex]]
  if not regex_:match_str(word) and regex_l:match_str(word) then
    return assert(vim.fn.substitute(word, "^.", [[\l&]], ""))
  else
    return assert(
      vim.fn.substitute(
        word,
        [[\C\(_\)\=\(.\)]],
        [[\=submatch(1)==""?tolower(submatch(2)) : toupper(submatch(2))]],
        "g"
      )
    )
  end
end

---@param word string
---@return string
function M.mixedcase(word) return assert(vim.fn.substitute(M.camelcase(word), "^.", [[\u&]], "")) end

---@param word string
---@return string
function M.snakecase(word)
  word = assert(vim.fn.substitute(word, "::", "/", "g"))
  word = assert(vim.fn.substitute(word, [[\(\u\+\)\(\u\l\)]], [[\1_\2]], "g"))
  word = assert(vim.fn.substitute(word, [[\(\l\|\d\)\(\u\)]], [[\1_\2]], "g"))
  word = assert(vim.fn.substitute(word, [=[[.-]]=], "_", "g"))
  word = assert(vim.fn.tolower(word))
  return word
end

---@param word string
---@return string
function M.uppercase(word) return assert(vim.fn.toupper(M.snakecase(word))) end

---@param word string
---@return string
function M.dashcase(word) return assert(vim.fn.substitute(M.snakecase(word), "_", "-", "g")) end

---@param word string
---@return string
function M.spacecase(word) return assert(vim.fn.substitute(M.snakecase(word), "_", " ", "g")) end

---@param word string
---@return string
function M.dotcase(word) return assert(vim.fn.substitute(M.snakecase(word), "_", ".", "g")) end

---@param parsed abolish.parsed_input
---@param opts table<string, any>
local function create_dictionary(parsed, opts)
  ---@type table<string, string>
  local dict = {}
  local expanded = expand_braces(parsed)

  local case = true
  if opts.case ~= nil then case = opts.case end
  for lhs, rhs in pairs(expanded) do
    if case then
      dict[M.mixedcase(lhs)] = M.mixedcase(rhs)
      dict[assert(vim.fn.tolower(lhs))] = vim.fn.tolower(rhs)
      dict[assert(vim.fn.toupper(lhs))] = vim.fn.toupper(rhs)
    end
    dict[lhs] = rhs
  end

  return dict
end

---@param a string
---@param b string
local function sort(a, b)
  local a_lower = vim.fn.tolower(a)
  local b_lower = vim.fn.tolower(b)
  if a_lower == b_lower then
    if a == b then
      return true
    elseif a > b then
      return false
    else
      return true
    end
  elseif #a == #b then
    return a_lower < b_lower
  else
    return #a > #b
  end
end

---@param pattern string
---@return string
local function subesc(pattern) return assert(vim.fn.substitute(pattern, [=[[][\\/.*+?~%()&]]=], [[\\&]], "g")) end

---@param dict table<string, string>
---@param boundaries number
local function pattern(dict, boundaries)
  ---@type string, string
  local a, b
  if boundaries == 2 then
    a = "<"
    b = ">"
  elseif boundaries == 1 then
    a = "%(<|_@<=|[[:lower:]]@<=[[:upper:]]@=)"
    b = "%(>|_@=|[[:lower:]]@<=[[:upper:]]@=)"
  else
    a = ""
    b = ""
  end
  if vim.tbl_isempty(dict) then
    dict = vim.empty_dict() --[[@as table]]
  end
  local keys = vim.fn.keys(dict)
  table.sort(keys, sort)
  return [[\v\C]] .. a .. "%(" .. table.concat(vim.tbl_map(subesc, keys), "|") .. ")" .. b
end

function Abolished()
  local submatch = vim.fn.submatch(0)
  return abolish_last_dict[submatch] and abolish_last_dict[submatch] or submatch
end

---@type abolish.highlight[]
local highlights

---@param s string
---@return string
-- TODO: handle multibyte chars
local function splice(s)
  ---@type string[]
  local chars = {}
  for i = 1, #s do
    chars[2 * i - 1] = s:sub(i, i)
    chars[2 * i] = "\n"
  end
  return table.concat(chars)
end

---@param count integer
---@param line1 integer
---@param line2 integer
---@param parsed abolish.parsed_input
---@param preview_ns integer|nil
local function substitute_command(count, line1, line2, parsed, preview_ns)
  ---@type string
  local cmd
  if count then
    cmd = line1 .. "," .. line2 .. "substitute"
  else
    cmd = "substitute"
  end

  ---@type string[]
  local lines_before
  ---@type integer[]
  local visible_line_range
  if preview_ns then
    lines_before = vim.api.nvim_buf_get_lines(0, line1 - 1, line2, true)
    visible_line_range = { vim.fn.line "w0", vim.fn.line "w$" }
  end

  if not preview_ns or (preview_ns and parsed.string) then
    local opts = normalize_options(parsed.flags or "")
    local dict = create_dictionary(parsed, opts)
    local lhs = pattern(dict, opts.boundaries)
    abolish_last_dict = dict

    vim.fn.execute(cmd .. "/" .. lhs .. [[/\=luaeval("Abolished()")]] .. "/" .. opts.flags)
  end

  if preview_ns then
    visible_line_range = {
      math.max(visible_line_range[1], vim.fn.line "w0"),
      math.max(visible_line_range[2], vim.fn.line "w$"),
    }

    parsed.pattern.before = assert(vim.fn.substitute(parsed.pattern.before, "\r", "\n", "g"))
    for i, v in ipairs(parsed.pattern.fragments) do
      parsed.pattern.fragments[i] = assert(vim.fn.substitute(v, "\r", "\n", "g"))
    end
    parsed.pattern.after = assert(vim.fn.substitute(parsed.pattern.after, "\r", "\n", "g"))

    local opts = normalize_options(parsed.flags or "")
    local preview_dict = create_dictionary(parsed, opts)
    local preview_lhs = pattern(preview_dict, opts.boundaries)
    abolish_last_dict = preview_dict
    ---@type string[]
    local lines_after = vim.tbl_map(
      ---@param line string
      function(line) return vim.fn.substitute(line, preview_lhs, [[\=luaeval("Abolished()")]], opts.flags or "") end,
      lines_before
    )
    ---@type string[]
    local splited_lines_after = {}
    for _, line_after in ipairs(lines_after) do
      for _, line in ipairs(vim.split(line_after, "\n", { trimempty = true })) do
        table.insert(splited_lines_after, line)
      end
    end

    local max_lines = math.max(#lines_before, #splited_lines_after)
    if #lines_before > #splited_lines_after then
      ---@type string[]
      local offset = {}
      for _ = #splited_lines_after, #lines_before - 1 do
        table.insert(offset, "")
      end
      vim.list_extend(offset, splited_lines_after)
      splited_lines_after = offset
    elseif #lines_before < #splited_lines_after then
      ---@type string[]
      local offset = {}
      for _ = #lines_before, #splited_lines_after - 1 do
        table.insert(offset, "")
      end
      vim.list_extend(offset, lines_before)
      lines_before = offset
    end

    -- Future me: do not change `max_lines` to `max_lines + 1`. Lua loops work like this, it is not needed.
    for i = 1, max_lines do
      local row = line1 + i - 1
      if row > visible_line_range[2] then break end
      if row >= visible_line_range[1] then
        local line_before = splice(lines_before[i])
        local line_after = splice(splited_lines_after[i])
        local hunks = vim.diff(line_before, line_after, { result_type = "indices" }) --[=[@as integer[][]]=]
        for _, hunk in ipairs(hunks) do
          ---@type integer, integer, integer, integer
          local _, count_a, start_b, count_b = unpack(hunk)
          table.insert(highlights, {
            kind = "change",
            line = row,
            column = (count_b == 0) and start_b + 1 or start_b,
            length = math.max(count_b, count_a),
          })
        end
      end
    end
  end
end

---@param preview_ns integer|nil
---@param line1 number
---@param line2 number
---@param count number
---@param parsed abolish.parsed_input
local function parse_substitute(preview_ns, line1, line2, count, parsed)
  if not parsed.pattern and not parsed.string and not preview_ns then
    vim.notify("Argument required", vim.log.levels.ERROR)
    return
  end

  substitute_command(count, line1, line2, parsed, preview_ns)
end

---@param parsed abolish.parsed_input
local find_command = function(parsed)
  local opts = normalize_options(parsed.flags or "")
  local dict = create_dictionary(parsed, opts)
  local cmd = parsed.separator == "?" and "?" or "/"

  local search = pattern(dict, opts.boundaries)
  vim.fn.setreg("/", search)

  if opts.flags == "" or vim.fn.search(vim.fn.getreg "/", "n") == 0 then
    vim.cmd.execute([["normal! ]] .. cmd .. [[\<CR>"]])
  else
    vim.cmd.execute([["normal! ]] .. cmd .. cmd .. opts.flags .. [[\<CR>"]])
    vim.fn.histdel("search", -1)
  end
end

local DO_NOT_PREVIEW = 0
local PREVIEW_IN_CURRENT_BUFFER = 1

---@type table<abolish.highlight.kind, string>
local hl_groups = {
  insertion = "DiffAdd",
  deletion = "DiffDelete",
  change = "DiffChange",
}

---@alias abolish.highlight.kind "insertion" | "deletion" | "change"
---@alias abolish.highlight { kind : abolish.highlight.kind, line: integer, column: integer, length: integer}

---@return string[]
local function get_words()
  ---@type string[]
  local words = {}
  local lnum = assert(vim.fn.line "w0")
  while lnum <= vim.fn.line "w$" do
    local line = vim.fn.getline(lnum)
    local col = 0
    while vim.fn.match(line, [[\<\k\k\+\>]], col) ~= -1 do
      table.insert(words, vim.fn.matchstr(line, [[\<\k\k\+\>]], col))
      col = vim.fn.matchend(line, [[\<\k\k\+\>]], col)
    end
    lnum = lnum + 1
  end
  return words
end

---@param arg_lead string
---@param _cmd_line string
---@param _cursor_pos integer
---@return string[]
M.complete = function(arg_lead, _cmd_line, _cursor_pos)
  local start_with_search = vim.regex [=[^[/?]\k\+$]=] --[[@as vim.regex]]
  local does_not_start_with_search = vim.regex [=[^\k\+$]=] --[[@as vim.regex]]
  ---@type string[]
  local all_words
  if start_with_search:match_str(arg_lead) then
    local char = arg_lead:sub(1, 1)
    all_words = get_words()
    all_words = vim.tbl_map(
      ---@param word string
      function(word) return char .. word end,
      all_words
    )
  elseif does_not_start_with_search:match_str(arg_lead) then
    all_words = get_words()
  else
    return {}
  end

  ---@type table<string, boolean>
  local already_seen = {}

  local filtered_words = vim.tbl_filter(
    ---@param word string
    function(word)
      if already_seen[word] then return false end
      already_seen[word] = true
      return vim.startswith(word, arg_lead)
    end,
    all_words
  )
  return filtered_words
end

---@param opts abolish.command_opts|{preview_ns: integer}
---@param preview_ns integer
M.subvert_preview = function(opts, preview_ns)
  highlights = {}

  opts.preview_ns = preview_ns or vim.api.nvim_create_namespace "abolish"
  local t = M.subvert_dispatcher(opts)
  if not t then return DO_NOT_PREVIEW end
  if not t.pattern or (not opts.count and not t.string) then return DO_NOT_PREVIEW end

  for _, hl in ipairs(highlights) do
    local hl_group = hl_groups[hl.kind]
    vim.api.nvim_buf_add_highlight(
      0,
      opts.preview_ns,
      hl_group,
      hl.line - 1,
      hl.column - 1,
      hl.length == -1 and -1 or hl.column + hl.length - 1
    )
  end

  return PREVIEW_IN_CURRENT_BUFFER
end

M.coercions = {
  c = M.camelcase,
  m = M.mixedcase,
  p = M.mixedcase,
  s = M.snakecase,
  _ = M.snakecase,
  u = M.uppercase,
  U = M.uppercase,
  ["-"] = M.dashcase,
  k = M.dashcase,
  ["."] = M.dotcase,
  [" "] = M.spacecase,
}

local l = vim.lpeg
local P, S, V, C, Cg, Cmt, Cb, Ct = l.P, l.S, l.V, l.C, l.Cg, l.Cmt, l.Cb, l.Ct
local locale = l.locale {}

-- Own flags
-- I: Disable case variations (box, Box, BOX)
-- v: Match inside variable names (match my_box, myBox, but not mybox)
-- w: Match whole words (like surrounding with \< and \>)
M.grammar = P {
  "command",
  prefix = Cg(P "S", "command"),
  separator = -S [[\"| ]] * -locale.alnum * 1,
  start_separator = Cg(V "separator", "separator"),
  end_separator = Cmt(C(V "separator") * Cb "separator", function(_s, _i, a, b) return a == b end),
  char = locale.alnum + S "_-.",
  fragment = C(V "char" ^ 0) * P "," + C(V "char" ^ 0) * P "}",
  section = Ct(
    Cg(V "char" ^ 0, "before") * Cg(Ct((P "{" * V "fragment" ^ 1) ^ -1), "fragments") * Cg(V "char" ^ 0, "after")
  ),
  pattern = Cg(V "section", "pattern"),
  string = Cg(V "section", "string"),
  vim_flags = S "&ceginp#lr",
  own_flags = S "Ivw",
  flags = Cg((V "vim_flags" + V "own_flags") ^ 0, "flags"),
  command = Ct(
    V "prefix" ^ -1
      * V "start_separator"
      * V "pattern"
      * (V "end_separator" * V "string" * (V "end_separator" * V "flags") ^ -1) ^ -1
  ),
}

---@class abolish.section
---@field before string
---@field after string
---@field fragments string[]

---@class abolish.parsed_input
---@field command string
---@field separator string
---@field pattern abolish.section
---@field string? abolish.section
---@field flags string

---@param opts abolish.command_opts | {preview_ns: integer|nil}
---@return abolish.parsed_input?
M.subvert_dispatcher = function(opts)
  local count = opts.count

  ---@type abolish.parsed_input?
  local t = M.grammar:match(opts.args)
  if not t then
    if not opts.preview_ns then vim.notify(("Invalid input: %s"):format(opts.args), vim.log.levels.ERROR) end
    return
  end

  if count ~= 0 then
    parse_substitute(opts.preview_ns, opts.line1, opts.line2, opts.count, t)
  elseif not t.string then
    find_command(t)
  elseif t.pattern and t.flags and t.flags ~= "" then
    find_command(t)
  else
    parse_substitute(opts.preview_ns, opts.line1, opts.line2, opts.count, t)
  end
  return t
end

return M
