local M = {}

M.char = ""

function M.opertator_func()
  local ok, char = pcall(vim.fn.getcharstr)
  vim.cmd [[echo '' | redraw]]

  if not ok or char == "\27" then
    return
  end
  M.char = char

  vim.o.operatorfunc = "v:lua.require'personal.abolish'.coerce"
  return "g@"
end

---@param type "line"|"char"|"block"
function M.coerce(type)
  local selection, clipboard = vim.o.selection, vim.o.clipboard
  vim.o.selection = "inclusive"
  vim.opt.clipboard:remove "unnamedplus"
  vim.opt.clipboard:remove "unnamed"

  local regbody = vim.fn.getreg '"'
  local regtype = vim.fn.getregtype '"'
  ---@type integer
  local c = vim.v.count1
  local begin = vim.fn.getcurpos()
  ---@type string
  local move
  while c > 0 do
    c = c - 1
    if type == "line" then
      move = "'[V']"
    elseif type == "block" then
      move = [=[`[\<C-V>`]]=]
    else
      move = "`[v`]"
    end
    vim.cmd('noautocmd silent execute "normal! ' .. move .. 'y"')
    local word = vim.fn.getreg '"'
    vim.fn.setreg('"', M.coercions[M.char](word))
    if word ~= vim.fn.getreg '"' then
      vim.cmd('noautocmd execute "normal! ' .. move .. 'p"')
    end
  end
  ---@diagnostic disable-next-line: param-type-mismatch
  vim.fn.setreg('"', regbody, regtype)
  vim.fn.setpos("'[", begin)
  vim.fn.setpos(".", begin)

  vim.o.selection, vim.o.clipboard = selection, clipboard
end

--- @type table<string, string>
local abolish_last_dict

--- @alias abolish.command_opts {name: string, args: string, fargs: string[], bang: boolean, line1: number, line2: number, range: number, count: number, reg: string, mods: string, smods: string[]}

---@param flags string|table<string, any>
local function normalize_options(flags)
  --- @type table<string, any>, string
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

  local i_flag = vim.regex "i" --[[@ as vim.regex]]
  opts.case = opts.case or true
  opts.case = not i_flag:match_str(flags) and opts.case or false
  opts.flags = vim.fn.substitute(flags, [=[\C[avIiw]]=], "", "g")
  return opts
end

---@param dict table<string, string>
local function expand_braces(dict)
  ---@type table<string, string>
  local new_dict = {}

  ---@type boolean
  local redo

  local regex = vim.regex "{.*}" --[[@as vim.regex]]
  for key, val in pairs(dict) do
    if regex:match_str(key) then
      redo = true
      ---@type string, string, string, string
      local all, kbefore, kmiddle, kafter = unpack(vim.fn.matchlist(key, [[\(.\{-\}\){\(.\{-\}\)}\(.*\)]]))
      ---@type string, string, string, string
      local _all, vbefore, vmiddle, vafter = unpack(vim.fn.matchlist(val, [[\(.\{-\}\){\(.\{-\}\)}\(.*\)]]))
      all = all or _all or ""
      vbefore, vmiddle, vafter = vbefore or "", vmiddle or "", vafter or ""

      if all == "" then
        vbefore, vmiddle, vafter = val, ",", ""
      end

      local targets = vim.fn.split(kmiddle, ",", 1)
      local replacements = vim.fn.split(vmiddle, ",", 1)

      if #replacements == 1 and replacements[1] == "" then
        replacements = targets
      end

      for i = 1, #targets do
        new_dict[kbefore .. targets[i] .. kafter] = vbefore .. replacements[((i - 1) % #replacements + 1)] .. vafter
      end
    else
      new_dict[key] = val
    end
  end

  if redo then
    return expand_braces(new_dict)
  else
    return new_dict
  end
end

---@param word string
function M.camelcase(word)
  word = vim.fn.substitute(word, "-", "_", "g")
  local regex_ = vim.regex "_" --[[@as vim.regex]]
  local regex_l = vim.regex [[\l]] --[[@as vim.regex]]
  if not regex_:match_str(word) and regex_l:match_str(word) then
    return vim.fn.substitute(word, "^.", [[\l&]], "")
  else
    return vim.fn.substitute(
      word,
      [[\C\(_\)\=\(.\)]],
      [[\=submatch(1)==""?tolower(submatch(2)) : toupper(submatch(2))]],
      "g"
    )
  end
end

---@param word string
function M.mixedcase(word)
  return vim.fn.substitute(M.camelcase(word), "^.", [[\u&]], "")
end

---@param word string
function M.snakecase(word)
  word = vim.fn.substitute(word, "::", "/", "g")
  word = vim.fn.substitute(word, [[\(\u\+\)\(\u\l\)]], [[\1_\2]], "g")
  word = vim.fn.substitute(word, [[\(\l\|\d\)\(\u\)]], [[\1_\2]], "g")
  word = vim.fn.substitute(word, [=[[.-]]=], "_", "g")
  word = vim.fn.tolower(word)
  return word
end

---@param word string
function M.uppercase(word)
  return vim.fn.toupper(M.snakecase(word))
end

---@param word string
function M.dashcase(word)
  return vim.fn.substitute(M.snakecase(word), "_", "-", "g")
end

---@param word string
function M.spacecase(word)
  return vim.fn.substitute(M.snakecase(word), "_", " ", "g")
end

---@param word string
function M.dotcase(word)
  return vim.fn.substitute(M.snakecase(word), "_", ".", "g")
end

---@param lhs string
---@param rhs string
---@param opts table<string, any>
local function create_dictionary(lhs, rhs, opts)
  ---@type table<string, string>
  local dict = {}
  local expanded = expand_braces { [lhs] = rhs }

  local case = true
  if opts.case ~= nil then
    case = opts.case
  end
  for lhs, rhs in pairs(expanded) do
    if case then
      dict[M.mixedcase(lhs)] = M.mixedcase(rhs)
      dict[vim.fn.tolower(lhs)] = vim.fn.tolower(rhs)
      dict[vim.fn.toupper(lhs)] = vim.fn.toupper(rhs)
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
local function subesc(pattern)
  return vim.fn.substitute(pattern, [=[[][\\/.*+?~%()&]]=], [[\\&]], "g")
end

---@param dict table<string, string>
---@param boundaries number
local function pattern(dict, boundaries)
  --- @type string, string
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
  --- @type string[]
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
---@param bad string
---@param good string
---@param flags string
---@param preview_ns integer|nil
local function substitute_command(count, line1, line2, bad, good, flags, preview_ns)
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

  local opts = normalize_options(flags)
  local dict = create_dictionary(bad, good, opts)
  local lhs = pattern(dict, opts.boundaries)
  abolish_last_dict = dict

  vim.fn.execute(cmd .. "/" .. lhs .. [[/\=luaeval("Abolished()")]] .. "/" .. opts.flags)

  if preview_ns and not (good == "") then
    visible_line_range = {
      math.max(visible_line_range[1], vim.fn.line "w0"),
      math.max(visible_line_range[2], vim.fn.line "w$"),
    }

    -- use "" by default to preview matches while searching (before replace)
    local preview_good = good or ""
    preview_good = vim.fn.substitute(preview_good, "\r", "\n", "g")
    local preview_dict = create_dictionary(bad, preview_good, opts)
    local preview_lhs = pattern(preview_dict, opts.boundaries)
    abolish_last_dict = preview_dict
    --- @type string[]
    local lines_after = vim.tbl_map(
      ---@param line string
      function(line)
        return vim.fn.substitute(line, preview_lhs, [[\=luaeval("Abolished()")]], opts.flags or "")
      end,
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

    for i = 1, max_lines + 1 do
      local row = line1 + i - 1
      if row > visible_line_range[2] then
        break
      end
      local splited_preview_good = vim.split(preview_good, "\n", {})
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
            column = splited_preview_good[i] == "" and start_b + 1 or start_b,
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
---@param args string[]
local function parse_substitute(preview_ns, line1, line2, count, args)
  local regex = vim.regex [=[^[/?]]=] --[[@as vim.regex]]
  if regex:match_str(args[1]) then
    local separator = args[1]:sub(1, 1)
    args = vim.fn.split(vim.fn.join(args, ""), separator, true) --[=[@as string[]]=]
    args = vim.list_slice(args, 2)
  end

  if #args < 2 and not preview_ns then
    vim.notify "E471: Argument required"
  elseif #args > 3 and not preview_ns then
    vim.notify "E488: Trailing characters"
  end

  ---@type string, string, string
  local bad, good, flags = unpack(args)
  flags = flags or ""

  substitute_command(count, line1, line2, bad, good, flags, preview_ns)
end

---@param cmd string
---@param flags string
---@param word string
local find_command = function(cmd, flags, word)
  local opts = normalize_options(flags)
  local dict = create_dictionary(word, "", opts)
  cmd = vim.regex("[?!]$"):match_str(cmd) and "?" or "/"

  local search = pattern(dict, opts.boundaries)
  vim.fn.setreg("/", search)

  if opts.flags == "" or vim.fn.search(vim.fn.getreg "/", "n") == 0 then
    vim.cmd.execute([["normal! ]] .. cmd .. [[\<CR>"]])
  elseif vim.regex([=[;[/?]\@!]=]):match_str(opts.flags) then
    vim.notify "E386: Expected '?' or '/' after ';'"
  else
    vim.cmd.execute([["normal! ]] .. cmd .. cmd .. opts.flags .. [[\<CR>"]])
    vim.fn.histdel("search", -1)
  end
end

--- @param opts abolish.command_opts | {preview_ns: integer|nil}
M.subvert_dispatcher = function(opts)
  local args = opts.args
  local count = opts.count

  local bang_regex = vim.regex [[^\%(\w\|$\)]] --[[@as vim.regex]]
  if bang_regex:match_str(args) then
    args = (opts.bang and "!" or "") .. args
  end

  local first_char = args:sub(1, 1)
  if first_char == "?" then
    first_char = [[\]] .. first_char
  end
  local separator = [[\v((\\)@<!(\\\\)*\\)@<!]] .. first_char
  local split = vim.fn.split(args, separator, true)
  split = vim.list_slice(split, 2)

  local search_flags = vim.regex [=[^[A-Za-z]*\%([+-]\d\+\)\=$]=] --[[@as vim.regex]]
  if count ~= 0 or (#split == 1 and split[1] == "") then
    return parse_substitute(opts.preview_ns, opts.line1, opts.line2, opts.count, split)
  elseif #split == 1 then
    return find_command(separator, "", split[1])
  elseif #split == 2 and search_flags:match_str(split[2]) then
    return find_command(separator, split[2], split[1])
  else
    return parse_substitute(opts.preview_ns, opts.line1, opts.line2, opts.count, split)
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

--- @alias abolish.highlight.kind "insertion" | "deletion" | "change"
--- @alias abolish.highlight { kind : abolish.highlight.kind, line: integer, column: integer, length: integer}

---@return string[]
local function get_words()
  --- @type string[]
  local words = {}
  local lnum = vim.fn.line "w0"
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
  --- @type string[]
  local all_words
  if start_with_search:match_str(arg_lead) then
    local char = arg_lead:sub(1, 1)
    all_words = get_words()
    all_words = vim.tbl_map(
      ---@param word string
      function(word)
        return char .. word
      end,
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
      if already_seen[word] then
        return false
      end
      already_seen[word] = true
      return vim.startswith(word, arg_lead)
    end,
    all_words
  )
  return filtered_words
end

--- @param opts abolish.command_opts
--- @param preview_ns integer
M.subvert_preview = function(opts, preview_ns)
  highlights = {}

  local separator = opts.args:sub(1, 1)
  local _, occurrences = opts.args:gsub(separator, "")

  if occurrences < 2 and opts.count == 0 and #opts.args <= 1 then
    return DO_NOT_PREVIEW
  end

  ---@cast opts + {preview_ns: integer}
  opts.preview_ns = preview_ns
  M.subvert_dispatcher(opts)

  for _, hl in ipairs(highlights) do
    local hl_group = hl_groups[hl.kind]
    vim.api.nvim_buf_add_highlight(
      0,
      preview_ns,
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

return M
