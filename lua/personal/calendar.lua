-- based on https://github.com/itchyny/calendar.vim

-- TODO: maybe change asserts to vim.notify errors (?)
-- TODO: maybe show notifications (maybe using mini.notify(to show progress)) while loading/waiting for responses (?)
local uv = vim.uv
local api = vim.api
local keymap = vim.keymap
local iter = vim.iter
local compute_hex_color_group = require("mini.hipatterns").compute_hex_color_group
local hl_enable = require("mini.hipatterns").enable
local notify = require "mini.notify"
local fs_exists = require("personal.util.general").fs_exists
local new_uid = require("personal.util.general").new_uid
local url_encode = require("personal.util.general").url_encode
local auv = require "personal.auv"

local M = {}

local api_key = vim.env.GOOGLE_CALENDAR_API_KEY ---@type string
local client_id = vim.env.GOOGLE_CALENDAR_CLIENT_ID ---@type string
local client_secret = vim.env.GOOGLE_CALENDAR_CLIENT_SECRET ---@type string

local data_path = ("%s/%s"):format(vim.fn.stdpath "data", "/calendar")
data_path = vim.fs.normalize(data_path)

local _timezone1, _timezone2 = tostring(os.date "%z"):match "([-+]%d%d)(%d%d)"
local timezone = ("%s:%s"):format(_timezone1, _timezone2)
-- TODO: hardcoded timezone
local text_timezone = "America/Guayaquil"

---@param opts {on_ready: fun(), on_code: fun(code: string)}
local function start_server(opts)
  local server = assert(uv.new_tcp())
  local buffer = {} ---@type string[]

  server:bind("127.0.0.1", 8080)
  server:listen(180, function(err)
    assert(not err, err)
    local client = uv.new_tcp()
    assert(server:accept(client))
    assert(client:read_start(vim.schedule_wrap(
      ---@param err2 string|nil
      ---@param data string|nil
      function(err2, data)
        assert(not err2, err2)
        if data then table.insert(buffer, data) end
        if data and data:find "\r\n\r\n$" then
          local request = table.concat(buffer, "")
          local lines = vim.split(request, "\r\n", { trimempty = true })
          local code = lines[1]:match "code=([^&]+)&"
          local err3 = lines[1]:match "error=([^&]+)&"
          assert(not err3, err3)
          assert(uv.write(
            client,
            ([[HTTP/1.1 200 OK
Content-Type: text/html

<!DOCTYPE html>
<html>
  <body>
    <h1>Everything done, you can close this and return to Neovim :D</h1>
  </body>
</html>
]]):format(code)
          ))
          assert(uv.read_stop(client))
          uv.close(client)
          uv.close(server)

          opts.on_code(code)
        end
      end
    )))
  end)
  opts.on_ready()
end

local token_url = "https://oauth2.googleapis.com/token"
local refresh_token_path = ("%s/refresh_token.json"):format(data_path)
local _cache_token_info ---@type TokenInfo|nil
local is_refreshing_access_token = false

---@async
---@param refresh_token string
---@return TokenInfo
local function refresh_access_token(refresh_token)
  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  local token_refreshed_pattern = "CalendarAccessTokenRefreshed"
  api.nvim_create_autocmd("User", {
    pattern = token_refreshed_pattern,
    ---@param opts {data:{token_info: TokenInfo}}
    callback = function(opts)
      local ok, err = coroutine.resume(co, opts.data.token_info)
      if not ok then vim.notify(err, vim.log.levels.ERROR) end
    end,
    once = true,
  })
  if is_refreshing_access_token then return coroutine.yield() end
  is_refreshing_access_token = true

  local params = ("client_id=%s&client_secret=%s&grant_type=refresh_token&refresh_token=%s"):format(
    client_id,
    client_secret,
    refresh_token
  )
  vim.system(
    {
      "curl",
      "--data",
      params,
      "--http1.1",
      "--silent",
      token_url,
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)
      local ok, new_token_info = pcall(vim.json.decode, result.stdout) ---@type boolean, NewTokenInfo|ApiTokenErrorResponse|string
      assert(ok, new_token_info)
      ---@cast new_token_info -string

      if new_token_info.error then
        ---@cast new_token_info -NewTokenInfo
        assert(new_token_info.error == "invalid_grant", vim.inspect(new_token_info))

        _cache_token_info = nil
        assert(vim.fn.delete(refresh_token_path) == 0, ("Couldn't delete file %s"):format(refresh_token_path))

        coroutine.wrap(function()
          local token_info = M.get_token_info()
          assert(token_info, "There is no token_info")
          is_refreshing_access_token = false
          api.nvim_exec_autocmds("User", { pattern = token_refreshed_pattern, data = { token_info = token_info } })
        end)()

        return
      end
      ---@cast new_token_info +NewTokenInfo
      ---@cast new_token_info -ApiTokenErrorResponse

      _cache_token_info.access_token = new_token_info.access_token
      _cache_token_info.expires_in = new_token_info.expires_in
      _cache_token_info.scope = new_token_info.scope
      _cache_token_info.token_type = new_token_info.token_type

      local file = io.open(refresh_token_path, "w")
      assert(file)
      local ok2, token_info_string = pcall(vim.json.encode, _cache_token_info) ---@type boolean, string
      assert(ok2, token_info_string)
      file:write(token_info_string)
      file:close()

      is_refreshing_access_token = false
      api.nvim_exec_autocmds("User", { pattern = token_refreshed_pattern, data = { token_info = _cache_token_info } })
    end)
  )
  return coroutine.yield()
end

local scope = "https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/tasks"
scope = assert(url_encode(scope))
local redirect_uri = "http://localhost:8080"
redirect_uri = assert(url_encode(redirect_uri))

local auth_url = "https://accounts.google.com/o/oauth2/auth"
local full_auth_url = ("%s?client_id=%s&redirect_uri=%s&scope=%s&response_type=code"):format(
  auth_url,
  client_id,
  redirect_uri,
  scope
)

---@class TokenInfo
---@field access_token string
---@field expires_in integer
---@field refresh_token string
---@field scope string
---@field token_type string

---@class NewTokenInfo
---@field access_token string
---@field expires_in integer
---@field scope string
---@field token_type string

---Reads from file if exists and asks for a token if not. May return an invalid/revoked token
---@async
---@return TokenInfo|nil
function M.get_token_info()
  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  if _cache_token_info then return _cache_token_info end

  local exists, err = fs_exists(refresh_token_path)
  if exists == nil and err then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
  if exists then
    local fd
    err, fd = auv.fs_open(refresh_token_path, "r", 292) ---444
    if err then return vim.notify(err, vim.log.levels.ERROR) end
    ---@cast fd -nil
    local stat
    err, stat = auv.fs_fstat(fd)
    if err then return vim.notify(err, vim.log.level.ERROR) end
    ---@cast stat -nil
    local content ---@type string|nil
    err, content = auv.fs_read(fd, stat.size, 0)
    if err then return vim.notify(err, vim.log.level.ERROR) end
    ---@cast content -nil
    err = auv.fs_close(fd)
    if err then return vim.notify(err, vim.log.level.ERROR) end

    local ok, token_info = pcall(vim.json.decode, content) ---@type boolean, string|TokenInfo
    assert(ok, token_info)
    ---@cast token_info -string

    _cache_token_info = token_info
    return token_info
  end

  start_server {
    on_ready = function() vim.ui.open(full_auth_url) end,
    on_code = function(code)
      local params = ("client_id=%s&client_secret=%s&code=%s&grant_type=authorization_code&redirect_uri=%s"):format(
        client_id,
        client_secret,
        code,
        redirect_uri
      )

      vim.system({
        "curl",
        "--data",
        params,
        "--http1.1",
        "--silent",
        -- TODO: is this needed?
        -- "--insecure",
        token_url,
      }, { text = true }, function(result)
        assert(result.stderr == "", result.stderr)

        local ok, token_info = pcall(vim.json.decode, result.stdout) ---@type boolean, string|TokenInfo
        assert(ok, token_info)
        ---@cast token_info -string

        local file = io.open(refresh_token_path, "w")
        assert(file)
        file:write(result.stdout)
        file:close()

        _cache_token_info = token_info
        ok, err = coroutine.resume(co, token_info)
        if not ok then vim.notify(err, vim.log.levels.ERROR) end
      end)
    end,
  }
  return coroutine.yield()
end

---@class DefaultReminder
---@field method string
---@field minutes integer

---@class Notification
---@field type string
---@field method string

---@class NotificationSettings
---@field notifications Notification[]

---@class ConferenceProperties
---@field allowedConferenceSolutionTypes string[]

---@class CalendarListEntry
---@field kind "calendar#calendarListEntry"
---@field etag string
---@field id string
---@field summary string
---@field description string
---@field location string
---@field timeZone string
---@field summaryOverride string
---@field colorId string
---@field backgroundColor string?
---@field foregroundColor string?
---@field hidden boolean
---@field selected boolean
---@field accessRole string
---@field defaultReminder DefaultReminder[]
---@field notificationSettings NotificationSettings
---@field primary boolean
---@field deleted boolean
---@field conferenceProperties ConferenceProperties

---@class CalendarList
---@field kind "calendar#calendarList"
---@field etag string
---@field nextPageToken string
---@field nextSyncToken string
---@field items CalendarListEntry[]

---@class Error
---@field domain string
---@field location string
---@field locationType string
---@field message string
---@field reason string

---@class ApiError
---@field code integer http error code
---@field errors Error[]
---@field message string
---@field status string

---@class ApiErrorResponse
---@field error ApiError

---@class ApiTokenErrorResponse
---@field error string
---@field error_description string

local _cache_calendar_list ---@type CalendarList|nil

---@async
---@param token_info TokenInfo
---@param opts? {refresh:true}
---@return CalendarList, TokenInfo|nil
function M.get_calendar_list(token_info, opts)
  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  if opts and opts.refresh then _cache_calendar_list = nil end

  if _cache_calendar_list then return _cache_calendar_list end

  vim.system(
    {
      "curl",
      "--http1.1",
      "--silent",
      "--header",
      ("Authorization: Bearer %s"):format(token_info.access_token),
      "https://www.googleapis.com/calendar/v3/users/me/calendarList",
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)
      local ok, calendar_list = pcall(vim.json.decode, result.stdout) ---@type boolean, string|CalendarList|ApiErrorResponse
      assert(ok, calendar_list)
      ---@cast calendar_list -string

      if calendar_list.error then
        ---@cast calendar_list -CalendarList
        assert(calendar_list.error.status == "UNAUTHENTICATED", calendar_list.error.message)
        coroutine.wrap(function()
          local refreshed_token_info = refresh_access_token(token_info.refresh_token)
          local new_calendar_list = M.get_calendar_list(refreshed_token_info, {})
          local err
          ok, err = coroutine.resume(co, new_calendar_list, refreshed_token_info)
          if not ok then vim.notify(err, vim.log.levels.ERROR) end
        end)()

        return
      end
      ---@cast calendar_list +CalendarList
      ---@cast calendar_list -ApiErrorResponse

      _cache_calendar_list = calendar_list
      local err
      ok, err = coroutine.resume(co, calendar_list, nil)
      if not ok then vim.notify(err, vim.log.levels.ERROR) end
    end)
  )
  return coroutine.yield()
end

local sep = " | "
---@param opts? {refresh:boolean}
function M.calendar_list_show(opts)
  coroutine.wrap(function()
    local token_info = M.get_token_info()
    assert(token_info, "There is no token_info")
    local calendar_list = M.get_calendar_list(token_info, opts)

    local buf = api.nvim_create_buf(false, false)
    api.nvim_buf_set_name(buf, "calendar://calendar_list")
    api.nvim_create_autocmd("BufLeave", {
      buffer = buf,
      callback = function() api.nvim_buf_delete(buf, { force = true }) end,
      once = true,
    })

    local factor = 0.85
    local width = math.floor(vim.o.columns * factor)
    local height = math.floor(vim.o.lines * factor)
    local col = (vim.o.columns - width) / 2
    local row = (vim.o.lines - height) / 2
    local win = api.nvim_open_win(buf, true, {
      relative = "editor",
      row = row,
      col = col,
      width = width,
      height = height,
      title = " Calendar list ",
      border = "single",
      style = "minimal",
    })

    api.nvim_create_autocmd("BufWriteCmd", {
      buffer = buf,
      callback = function()
        vim.bo[buf].modifiable = false

        ---@type table<string, CalendarListEntry>
        local calendars_by_id = iter(calendar_list.items):fold(
          {},
          ---@param acc table<string, CalendarListEntry>
          ---@param calendar CalendarListEntry
          function(acc, calendar)
            acc[calendar.id] = calendar
            return acc
          end
        )

        local lines = api.nvim_buf_get_lines(buf, 0, -1, true)
        local diffs = {} ---@type CalendarDiff[]
        iter(lines)
          :map(
            ---@param line string
            ---@return {summary:string, description:string, id: string?, is_new: boolean}
            function(line)
              if line:match "^/[^ ]+" then -- existing entry
                local id, tail = line:match "^/([^ ]+) (.*)" ---@type string, string
                local summary, description = unpack(vim.split(tail, sep, { trimempty = true }))
                return {
                  summary = summary,
                  description = description,
                  id = id,
                  is_new = false,
                }
              else
                local summary, description = unpack(vim.split(line, sep, { trimempty = true }))
                return {
                  summary = summary,
                  description = description,
                  is_new = true,
                }
              end
            end
          )
          :each(
            ---@param calendar_info {summary:string, description:string, id: string?, is_new: boolean}
            function(calendar_info)
              local is_new = calendar_info.is_new
              local summary = calendar_info.summary
              local id = calendar_info.id

              if not is_new then
                ---@cast id -nil

                assert(_cache_calendar_list)
                local cached_calendar = iter(_cache_calendar_list.items):find(
                  ---@param calendar CalendarListEntry
                  function(calendar) return calendar.id == id end
                )
                assert(
                  cached_calendar,
                  ("The calendar with id `%s` is not in cache. Maybe you modified it by acciddent"):format(id)
                )
                assert(summary, ("The calendar with id `%s` has no summary"):format(id))
                calendars_by_id[id] = nil

                local edit_diff = {}
                if summary ~= cached_calendar.summary then edit_diff.summary = summary end
                if not vim.tbl_isempty(edit_diff) then
                  edit_diff.cached_calendar = cached_calendar
                  edit_diff.type = "edit"
                  table.insert(diffs, edit_diff)
                end
              else
                -- TODO: support adding an already existing calendar https://developers.google.com/calendar/api/v3/reference/calendarList/insert
                assert(summary ~= "", "The summary for a new calendar is empty")
                table.insert(diffs, {
                  type = "new",
                  summary = summary,
                })
              end
            end
          )

        iter(calendars_by_id):each(
          function(_id, calendar) table.insert(diffs, { type = "delete", cached_calendar = calendar }) end
        )

        local diff_num = #diffs
        local i = 0
        local reload_if_last_diff = function()
          i = i + 1
          if i == diff_num then
            api.nvim_win_close(win, true)
            M.calendar_list_show()
          end
        end
        iter(diffs):each(
          ---@param diff CalendarDiff
          function(diff)
            if diff.type == "new" then
              assert(diff.summary, ("Diff has no summary %s"):format(vim.inspect(diff)))
              coroutine.wrap(function()
                token_info = M.get_token_info()
                assert(token_info, "There is no token_info")
                local new_calendar = M.create_calendar(token_info, diff)
                assert(_cache_calendar_list)
                table.insert(_cache_calendar_list.items, new_calendar)

                reload_if_last_diff()
              end)()
            elseif diff.type == "edit" then
              coroutine.wrap(function()
                token_info = M.get_token_info()
                assert(token_info, "There is no token_info")
                local edited_calendar = M.edit_calendar(token_info, diff)
                local cached_calendar = diff.cached_calendar --[[@as table<unknown, unknown>]]

                -- can't only update some fields because google checks
                -- things like the last update time to check if the
                -- calendar has gone out-of-sync
                for key, _ in pairs(edited_calendar) do
                  cached_calendar[key] = edited_calendar[key]
                end

                reload_if_last_diff()
              end)()
            elseif diff.type == "delete" then
              coroutine.wrap(function()
                token_info = M.get_token_info()
                assert(token_info, "There is no token_info")
                M.delete_calendar(token_info, diff)
                assert(_cache_calendar_list)
                for j, calendar in ipairs(_cache_calendar_list.items) do
                  if calendar.id == diff.cached_calendar.id then table.remove(_cache_calendar_list.items, j) end
                end

                reload_if_last_diff()
              end)()
            end
          end
        )

        vim.bo[buf].modified = false
        vim.bo[buf].modifiable = true
      end,
    })
    local highlighters = {
      conceal_id = {
        pattern = "^()/[^ ]+ ()",
        group = "", -- group needs to not be `nil` to work
        extmark_opts = {
          conceal = "",
        },
      },
      time = {
        pattern = "[ :]()%d%d()",
        group = "Number",
      },
      punctuation = {
        pattern = { sep, ":" },
        group = "Delimiter",
      },
    }
    local lines = iter(calendar_list.items)
      :map(
        ---@param calendar CalendarListEntry
        function(calendar)
          if calendar.foregroundColor then
            local fg = compute_hex_color_group(calendar.foregroundColor, "fg")
            highlighters[calendar.id .. "fg"] = { pattern = "%f[%w]()" .. calendar.summary .. "()%f[%W]", group = fg }
          end
          if calendar.backgroundColor then
            local bg = compute_hex_color_group(calendar.backgroundColor, "bg")
            highlighters[calendar.id .. "bg"] = { pattern = "%f[%w]()" .. calendar.summary .. "()%f[%W]", group = bg }
          end

          if calendar.accessRole == "reader" then
            highlighters[calendar.id .. "deprecated"] =
              { pattern = "%f[%w]()" .. calendar.summary .. "()%f[%W]", group = "DiagnosticDeprecated" }
          end

          local line = ("/%s %s%s%s"):format(calendar.id, calendar.summary, sep, calendar.description or "")
          return line
        end
      )
      :totable()
    api.nvim_buf_set_lines(buf, 0, -1, true, lines)
    hl_enable(buf, { highlighters = highlighters })

    keymap.set("n", "<cr>", function()
      local line = api.nvim_get_current_line()
      local id = line:match "^/([^ ]+) " ---@type string, string

      api.nvim_win_close(0, true)
      M.calendar_show(id)
    end, { buffer = buf })
    keymap.set("n", "<F5>", function()
      api.nvim_win_close(win, true)
      M.calendar_list_show { refresh = true }
    end, { buffer = buf })
  end)()
end

---@class Calendar
---@field kind "calendar#calendar"
---@field etag string
---@field id string
---@field summary string
---@field description string
---@field location string
---@field timeZone string
---@field conferenceProperties ConferenceProperties

local _cache_calendar = {} ---@type table<string, Calendar>

---@async
---@param token_info TokenInfo
---@param id string
---@return Calendar
function M.get_calendar(token_info, id)
  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  if _cache_calendar[id] then return _cache_calendar[id] end

  vim.system(
    {
      "curl",
      "--http1.1",
      "--silent",
      "--header",
      ("Authorization: Bearer %s"):format(token_info.access_token),
      ("https://www.googleapis.com/calendar/v3/calendars/%s"):format(url_encode(id)),
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)
      local ok, calendar = pcall(vim.json.decode, result.stdout) ---@type boolean, string|Calendar|ApiErrorResponse
      assert(ok, calendar)
      ---@cast calendar -string

      if calendar.error then
        ---@cast calendar -Calendar
        assert(calendar.error.status == "UNAUTHENTICATED", calendar.error.message)
        coroutine.wrap(function()
          local refreshed_token_info = refresh_access_token(token_info.refresh_token)
          local new_calendar = M.get_calendar(refreshed_token_info, id)
          local err
          ok, err = coroutine.resume(co, new_calendar)
          if not ok then vim.notify(err, vim.log.levels.ERROR) end
        end)()
        return
      end
      ---@cast calendar +Calendar
      ---@cast calendar -ApiErrorResponse

      _cache_calendar[id] = calendar
      local err
      ok, err = coroutine.resume(co, calendar)
      if not ok then vim.notify(err, vim.log.levels.ERROR) end
    end)
  )
  return coroutine.yield()
end

---@async
---@param token_info TokenInfo
---@param diff CalendarDiff
---@return Calendar
function M.create_calendar(token_info, diff)
  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  local data = vim.json.encode { summary = diff.summary }
  local tmp_name = os.tmpname()
  local tmp_file = io.open(tmp_name, "w")
  assert(tmp_file)
  tmp_file:write(data)
  tmp_file:close()

  vim.system(
    {
      "curl",
      "--data-binary",
      ("@%s"):format(tmp_name),
      "--http1.1",
      "--silent",
      "--header",
      ("Authorization: Bearer %s"):format(token_info.access_token),
      "https://www.googleapis.com/calendar/v3/calendars",
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)
      local ok, new_calendar = pcall(vim.json.decode, result.stdout) ---@type boolean, string|Calendar|ApiErrorResponse
      assert(ok, new_calendar)
      ---@cast new_calendar -string

      if new_calendar.error then
        ---@cast new_calendar -Calendar
        assert(new_calendar.error.status == "UNAUTHENTICATED", new_calendar.error.message)
        coroutine.wrap(function(refreshed_token_info)
          refresh_access_token(token_info.refresh_token)
          local new_new_calendar = M.create_calendar(refreshed_token_info, diff)
          local err
          ok, err = coroutine.resume(co, new_new_calendar)
          if not ok then vim.notify(err, vim.log.levels.ERROR) end
        end)()
        return
      end
      ---@cast new_calendar +Calendar
      ---@cast new_calendar -ApiErrorResponse

      local err
      ok, err = coroutine.resume(co, new_calendar)
      if not ok then vim.notify(err, vim.log.levels.ERROR) end
    end)
  )
  return coroutine.yield()
end

---@async
---@param token_info TokenInfo
---@param diff CalendarDiff
---@return Calendar
function M.edit_calendar(token_info, diff)
  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  local cached_calendar = vim.deepcopy(diff.cached_calendar)
  if diff.summary then cached_calendar.summary = diff.summary end
  local data = vim.json.encode(cached_calendar)
  local tmp_name = os.tmpname()
  local tmp_file = io.open(tmp_name, "w")
  assert(tmp_file)
  tmp_file:write(data)
  tmp_file:close()

  vim.system(
    {
      "curl",
      "--request",
      "PUT",
      "--data-binary",
      ("@%s"):format(tmp_name),
      "--http1.1",
      "--silent",
      "--header",
      ("Authorization: Bearer %s"):format(token_info.access_token),
      ("https://www.googleapis.com/calendar/v3/calendars/%s"):format(diff.cached_calendar.id),
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)
      local ok, edited_calendar = pcall(vim.json.decode, result.stdout) ---@type boolean, string|Calendar|ApiErrorResponse
      assert(ok, edited_calendar)
      ---@cast edited_calendar -string

      if edited_calendar.error then
        ---@cast edited_calendar -Calendar
        assert(edited_calendar.error.status == "UNAUTHENTICATED", edited_calendar.error.message)
        coroutine.wrap(function()
          local refreshed_token_info = refresh_access_token(token_info.refresh_token)
          local new_edited_calendar = M.edit_calendar(refreshed_token_info, diff)
          local err
          ok, err = coroutine.resume(co, new_edited_calendar)
          if not ok then vim.notify(err, vim.log.levels.ERROR) end
        end)()
        return
      end
      ---@cast edited_calendar +Calendar
      ---@cast edited_calendar -ApiErrorResponse

      local err
      ok, err = coroutine.resume(co, edited_calendar)
      if not ok then vim.notify(err, vim.log.levels.ERROR) end
    end)
  )
  return coroutine.yield()
end

---@async
---@param token_info TokenInfo
---@param diff CalendarDiff
function M.delete_calendar(token_info, diff)
  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  vim.system(
    {
      "curl",
      "--request",
      "DELETE",
      "--http1.1",
      "--silent",
      "--header",
      ("Authorization: Bearer %s"):format(token_info.access_token),
      ("https://www.googleapis.com/calendar/v3/calendars/%s"):format(diff.cached_calendar.id),
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)

      if result.stdout == "" then
        local ok, err = coroutine.resume(co)
        if not ok then vim.notify(err, vim.log.levels.ERROR) end
        return
      end

      local ok, response = pcall(vim.json.decode, result.stdout) ---@type boolean, string|ApiErrorResponse
      assert(ok, response)
      ---@cast response -string

      if response.error then
        ---@cast response -Event
        assert(response.error.status == "UNAUTHENTICATED", response.error.message)
        coroutine.wrap(function()
          local refreshed_token_info = refresh_access_token(token_info.refresh_token)
          M.delete_calendar(refreshed_token_info, diff)
          local err
          ok, err = coroutine.resume(co)
          if not ok then vim.notify(err, vim.log.levels.ERROR) end
        end)()
        return
      end
    end)
  )
  coroutine.yield()
end

---@param id string
function M.calendar_show(id)
  coroutine.wrap(function()
    local token_info = M.get_token_info()
    assert(token_info, "There is no token_info")

    local calendar = M.get_calendar(token_info, id)
    local buf = api.nvim_create_buf(false, false)

    api.nvim_create_autocmd("BufLeave", {
      buffer = buf,
      callback = function() api.nvim_buf_delete(buf, { force = true }) end,
      once = true,
    })
    local calendar_string = vim.json.encode(calendar)
    api.nvim_buf_set_lines(buf, 0, 0, true, vim.split(calendar_string, "\n"))
    api.nvim_buf_call(buf, function() vim.cmd.set "filetype=json" end)

    -- TODO: modify to put cursor on top of current calendar (?)
    keymap.set("n", "-", function()
      api.nvim_win_close(0, true)
      M.calendar_list_show()
    end, { buffer = buf })

    local width = math.floor(vim.o.columns * 0.85)
    local height = math.floor(vim.o.lines * 0.85)
    local col = (vim.o.columns - width) / 2
    local row = (vim.o.lines - height) / 2
    api.nvim_open_win(buf, true, {
      relative = "editor",
      row = row,
      col = col,
      width = width,
      height = height,
      title = " Calendar ",
      border = "single",
      style = "minimal",
    })
  end)()
end

---@class User
---@field id string
---@field email string
---@field displayName string
---@field self boolean

---@class Attendee: User
---@field organizer boolean
---@field resource boolean
---@field optional boolean
---@field responseStatus string
---@field comment string
---@field additionalGuests integer

---@class Date
---@field date string?
---@field dateTime string?
---@field timeZone string?

---@class ExtendedProperties
---@field public private table<string, string>
---@field shared table<string, string>

---@class CreateRequest
---@field requestId string
---@field conferenceSolutionKey {type: string}
---@field status {statusCode: string}

---@class EntryPoint
---@field entryPointType string
---@field uri string
---@field label string
---@field pin string
---@field accessCode string
---@field meetingCode string
---@field passcode string
---@field password string

---@class EntryPoint
---@field key {type: string}
---@field name string
---@field iconUri string

---@class Gadget
---@field type string
---@field title string
---@field link string
---@field iconLink string
---@field width integer
---@field height integer
---@field display string
---@field preferences table<string, string>

---@class Reminders
---@field useDefault boolean
---@field overrides {method: string, minutes: integer}[]

---@class Source
---@field url string
---@field title string

---@class ConferenceSolution
---@field key {type: string}
---@field name string,
---@field iconUri string

---@class ConferenceData
---@field createRequest CreateRequest
---@field entryPoints EntryPoint[]
---@field conferenceSolution ConferenceSolution
---@field conferenceId string
---@field signature string
---@field notes string

---@class WorkingLocationProperties
---@field type string
---@field homeOffice string
---@field customLocation {label: string}
---@field officeLocation { buildingId: string, floorId: string, floorSectionId: string, deskId: string, label: string}

---@class OutOfOfficeProperties
---@field autoDeclineMode string
---@field declineMessage string

---@class FocusTimeProperties
---@field autoDeclineMode string
---@field declineMessage string
---@field chatStatus string

---@class Attachment
---@field fileUrl string
---@field title string
---@field mimeType string
---@field iconLink string
---@field fileId string

---@class Event
---@field kind "calendar#event"
---@field etag string
---@field id string
---@field status string
---@field htmlLink string
---@field created string
---@field updated string
---@field summary string
---@field description string
---@field location string
---@field colorId string
---@field creator User
---@field organizer User
---@field start Date
---@field end Date
---@field endTimeUnspecified boolean
---@field recurrence string[]
---@field recurringEventId string
---@field originalStartTime Date
---@field transparency string
---@field visibility string
---@field iCalUID string
---@field sequence integer
---@field attendees Attendee[]
---@field attendeesOmitted boolean
---@field extendedProperties ExtendedProperties
---@field hangoutLink string
---@field conferenceData ConferenceData
---@field gadget Gadget
---@field anyoneCanAddSelf boolean
---@field guestsCanInviteOthers boolean
---@field guestsCanModify boolean
---@field guestsCanSeeOtherGuests boolean
---@field privateCopy boolean
---@field locked boolean
---@field reminders Reminders
---@field source Source
---@field workingLocationProperties WorkingLocationProperties
---@field outOfOfficeProperties OutOfOfficeProperties
---@field focusTimeProperties FocusTimeProperties
---@field attachments Attachment[]
---@field eventType string

---@class CalendarEvents
---@field kind "calendar#events"
---@field etag string
---@field summary string
---@field description string
---@field updated string
---@field timeZone string
---@field accessRole string
---@field defaultReminders DefaultReminder
---@field nextPageToken string
---@field nextSyncToken string
---@field items Event[]

local _cache_events = {} ---@type table<string, Event[]> year_month_day -> events
local already_seen = {} ---@type table<string, boolean>

---@class CalendarDate
---@field year integer
---@field month integer
---@field day integer

---@async
---@param token_info TokenInfo
---@param calendar_list CalendarList
---@param opts {start: CalendarDate, end: CalendarDate, refresh: boolean?, should_query_single_events: boolean?} start and end are exclusive
---@return table<string, Event[]>, TokenInfo|nil
function M.get_events(token_info, calendar_list, opts)
  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  if opts.refresh then
    _cache_events = {}
    already_seen = {}
  end
  if opts.should_query_single_events == nil then opts.should_query_single_events = true end

  local start_year = opts.start.year
  local start_month = opts.start.month
  local start_day = opts.start.day
  local end_year = opts["end"].year
  local end_month = opts["end"].month
  local end_day = opts["end"].day

  local time_min = ("%04d-%02d-%02dT00:00:00%s"):format(start_year, start_month, start_day, timezone)
  local time_max = ("%04d-%02d-%02dT00:00:00%s"):format(end_year, end_month, end_day, timezone)

  local start_key = ("%s_%s_%s"):format(start_year, start_month, start_day)
  local end_key = ("%s_%s_%s"):format(end_year, end_month, end_day)
  local events_key = ("%s_%s"):format(start_key, end_key)
  if already_seen[events_key] then return _cache_events end

  -- in order to avoid duplicates on border days, if the whole date range hasn't been queried before, clean border days
  do
    local start_date = opts.start
    local end_date = opts["end"]
    local start_yday = os.date("*t", os.time(start_date --[[@as osdateparam]])).yday
    local end_yday = os.date("*t", os.time(end_date--[[@as osdateparam]])).yday
    if end_yday < start_yday then end_yday = end_yday + 365 end
    for i = 0, end_yday - start_yday do
      local date = os.date("*t", os.time { year = start_date.year, month = start_date.month, day = start_date.day + i })
      local key = ("%s_%s_%s"):format(date.year, date.month, date.day)
      if _cache_events[key] then _cache_events[key] = {} end
    end
  end

  local count = 0
  iter(calendar_list.items):each(
    ---@param calendar CalendarListEntry
    function(calendar)
      vim.system(
        {
          "curl",
          "--http1.1",
          "--silent",
          "--header",
          ("Authorization: Bearer %s"):format(token_info.access_token),
          ("https://www.googleapis.com/calendar/v3/calendars/%s/events?timeMin=%s&timeMax=%s&singleEvents=%s"):format(
            url_encode(calendar.id),
            url_encode(time_min),
            url_encode(time_max),
            opts.should_query_single_events
          ),
        },
        { text = true },
        vim.schedule_wrap(function(result)
          assert(result.stderr == "", result.stderr)
          local ok, events = pcall(vim.json.decode, result.stdout) ---@type boolean, string|CalendarEvents|ApiErrorResponse
          assert(ok, events)
          ---@cast events -string

          if events.error then
            ---@cast events -CalendarEvents
            assert(events.error.status == "UNAUTHENTICATED", events.error.message)
            coroutine.wrap(function()
              local refreshed_token_info = refresh_access_token(token_info.refresh_token)
              local new_events = M.get_events(refreshed_token_info, calendar_list, opts)
              local err
              ok, err = coroutine.resume(co, new_events, refreshed_token_info)
              if not ok then vim.notify(err, vim.log.levels.ERROR) end
            end)()
            return
          end
          ---@cast events +CalendarEvents
          ---@cast events -ApiErrorResponse

          iter(events.items):each(
            ---@param event Event
            function(event)
              local start_date = M.parse_date_or_datetime(event.start, {})
              local end_date = M.parse_date_or_datetime(event["end"], { is_end = true })

              local start_yday =
                os.date("*t", os.time { year = start_date.y, month = start_date.m, day = start_date.d }).yday
              local end_yday = os.date("*t", os.time { year = end_date.y, month = end_date.m, day = end_date.d }).yday
              for i = 0, end_yday - start_yday do
                local date =
                  os.date("*t", os.time { year = start_date.y, month = start_date.m, day = start_date.d + i })
                local key = ("%s_%s_%s"):format(date.year, date.month, date.day)
                if not _cache_events[key] then _cache_events[key] = {} end
                table.insert(_cache_events[key], event)
              end
            end
          )

          count = count + 1
          if count == #calendar_list.items then
            already_seen[events_key] = true
            -- TODO: dedup multiple request like colors?
            local err
            ok, err = coroutine.resume(co, _cache_events, nil)
            if not ok then vim.notify(err, vim.log.levels.ERROR) end
          end
        end)
      )
    end
  )
  return coroutine.yield()
end

---@param date_time string
---@return {y: integer, m: integer, d: integer, h: integer, min: integer, s: integer, offset: string}
local function parse_date_time(date_time)
  ---@type string, string, string, string, string, string, string, string
  local y, m, d, h, min, s, offset = date_time:match "(%d%d%d%d)-(%d%d)-(%d%d)T(%d%d):(%d%d):(%d%d)([-+]%d%d:%d%d)"
  return {
    y = tonumber(y),
    m = tonumber(m),
    d = tonumber(d),
    h = tonumber(h),
    min = tonumber(min),
    s = tonumber(s),
    offset = offset,
  }
end

---@param date string
---@param opts {is_end: boolean}
---@return {y: integer, m: integer, d: integer}
local function parse_date(date, opts)
  ---@type string, string, string, string, string, string, string, string
  local y, m, d = date:match "(%d%d%d%d)-(%d%d)-(%d%d)"
  return {
    y = opts.is_end and tonumber(y) or tonumber(y),
    m = opts.is_end and tonumber(m) or tonumber(m),
    d = opts.is_end and tonumber(d) - 1 or tonumber(d), -- dates (without time) are end exclusive
  }
end

---@param date_or_date_time Date
---@param opts {is_end: boolean}
---@return {y: integer, m: integer, d: integer}
function M.parse_date_or_datetime(date_or_date_time, opts)
  if date_or_date_time.date then
    return parse_date(date_or_date_time.date, opts)
  elseif date_or_date_time.dateTime then
    return parse_date_time(date_or_date_time.dateTime)
  else
    error(("Date %s has no date or datetime"):format(vim.inspect(date_or_date_time)))
  end
end

---@class CalendarView
---@field year_buf integer
---@field year_win integer
---@field month_buf integer
---@field month_win integer
---@field day_bufs table<integer, integer> day_bufs[x] = buf 1-based
---@field day_wins table<integer, integer> day_wins[x] = win 1-based
---@field cal_bufs table<integer, table<integer, integer>> cal_bufs[y][x] = buf 1-based
---@field cal_wins table<integer, table<integer, integer>> cal_wins[y][x] = win 1-based
local CalendarView = {}
CalendarView.__index = CalendarView
CalendarView.d_in_w = 7
CalendarView.days = { "Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado" }
CalendarView.header_required_height = 6
CalendarView.months = {
  [[
 _____                         
|  ___|                        
| |__  _ __    ___  _ __  ___  
|  __|| '_ \  / _ \| '__|/ _ \ 
| |___| | | ||  __/| |  | (_) |
\____/|_| |_| \___||_|   \___/ 
]],
  [[
______     _                            
|  ___|   | |                           
| |_  ___ | |__   _ __  ___  _ __  ___  
|  _|/ _ \| '_ \ | '__|/ _ \| '__|/ _ \ 
| | |  __/| |_) || |  |  __/| |  | (_) |
\_|  \___||_.__/ |_|   \___||_|   \___/ 
]],
  [[
___  ___                        
|  \/  |                        
| .  . |  __ _  _ __  ____ ___  
| |\/| | / _` || '__||_  // _ \ 
| |  | || (_| || |    / /| (_) |
\_|  |_/ \__,_||_|   /___|\___/ 
]],
  [[
  ___   _            _  _ 
 / _ \ | |          (_)| |
/ /_\ \| |__   _ __  _ | |
|  _  || '_ \ | '__|| || |
| | | || |_) || |   | || |
\_| |_/|_.__/ |_|   |_||_|
]],
  [[
___  ___                     
|  \/  |                     
| .  . |  __ _  _   _   ___  
| |\/| | / _` || | | | / _ \ 
| |  | || (_| || |_| || (_) |
\_|  |_/ \__,_| \__, | \___/ 
                 __/ |       
                |___/        
]],
  [[
   ___                _        
  |_  |              (_)       
    | | _   _  _ __   _   ___  
    | || | | || '_ \ | | / _ \ 
/\__/ /| |_| || | | || || (_) |
\____/  \__,_||_| |_||_| \___/ 
]],
  [[
   ___         _  _        
  |_  |       | |(_)       
    | | _   _ | | _   ___  
    | || | | || || | / _ \ 
/\__/ /| |_| || || || (_) |
\____/  \__,_||_||_| \___/ 
]],
  [[
  ___                      _         
 / _ \                    | |        
/ /_\ \  __ _   ___   ___ | |_  ___  
|  _  | / _` | / _ \ / __|| __|/ _ \ 
| | | || (_| || (_) |\__ \| |_| (_) |
\_| |_/ \__, | \___/ |___/ \__|\___/ 
         __/ |                       
        |___/                        
]],
  [[
 _____               _    _                   _                
/  ___|             | |  (_)                 | |               
\ `--.   ___  _ __  | |_  _   ___  _ __ ___  | |__   _ __  ___ 
 `--. \ / _ \| '_ \ | __|| | / _ \| '_ ` _ \ | '_ \ | '__|/ _ \
/\__/ /|  __/| |_) || |_ | ||  __/| | | | | || |_) || |  |  __/
\____/  \___|| .__/  \__||_| \___||_| |_| |_||_.__/ |_|   \___|
             | |                                               
             |_|                                               
]],
  [[
 _____        _           _                
/  _  \      | |         | |               
| | | |  ___ | |_  _   _ | |__   _ __  ___ 
| | | | / __|| __|| | | || '_ \ | '__|/ _ \
\ \_/ /| (__ | |_ | |_| || |_) || |  |  __/
 \___/  \___| \__| \__,_||_.__/ |_|   \___|
]],
  [[
 _   _               _                   _                
| \ | |             (_)                 | |               
|  \| |  ___ __   __ _   ___  _ __ ___  | |__   _ __  ___ 
| . ` | / _ \\ \ / /| | / _ \| '_ ` _ \ | '_ \ | '__|/ _ \
| |\  || (_) |\ V / | ||  __/| | | | | || |_) || |  |  __/
\_| \_/ \___/  \_/  |_| \___||_| |_| |_||_.__/ |_|   \___|
]],
  [[
______  _        _                   _                
|  _  \(_)      (_)                 | |               
| | | | _   ___  _   ___  _ __ ___  | |__   _ __  ___ 
| | | || | / __|| | / _ \| '_ ` _ \ | '_ \ | '__|/ _ \
| |/ / | || (__ | ||  __/| | | | | || |_) || |  |  __/
|___/  |_| \___||_| \___||_| |_| |_||_.__/ |_|   \___|
]],
}

CalendarView.digits = {
  [0] = [[
 _____ 
/  _  \
| |/' |
|  /| |
\ |_/ /
 \___/ 
  ]],
  [[
 __  
/  | 
`| | 
 | | 
_| |_
\___/
  ]],
  [[
 _____ 
/ __  \
`' / /'
  / /  
./ /___
\_____/
  ]],
  [[
 _____ 
|____ |
    / /
    \ \
.___/ /
\____/ 
  ]],
  [[
   ___ 
  /   |
 / /| |
/ /_| |
\___  |
    |_/
  ]],
  [[
 _____ 
|  ___|
|___ \ 
    \ \
/\__/ /
\____/ 
  ]],
  [[
  ____ 
 / ___|
/ /___ 
| ___ \
| \_/ |
\_____/
  ]],
  [[
 ______
|___  /
   / / 
  / /  
./ /   
\_/    
  ]],
  [[
 _____ 
|  _  |
 \ V / 
 / _ \ 
| |_| |
\_____/
  ]],
  [[
 _____
|  _  |
| |_| |
\____ |
.___/ /
\____/
  ]],
}
CalendarView.months_short = {
  "Enero",
  "Febrero",
  "Marzo",
  "Abril",
  "Mayo",
  "Junio",
  "Julio",
  "Agosto",
  "Septiembre",
  "Octubre",
  "Noviembre",
  "Diciembre",
}

---@return CalendarView
function CalendarView.new()
  local self = {}
  self.m_y_bufs = {}
  self.m_y_wins = {}
  self.day_bufs = {}
  self.day_wins = {}
  self.cal_bufs = {}
  self.cal_wins = {}
  return setmetatable(self, CalendarView)
end

function CalendarView:w_in_m(year, month)
  local first_day = os.date("*t", os.time { year = year, month = month, day = 1 })
  local last_day = os.date("*t", os.time { year = year, month = month + 1, day = 0 })

  if (first_day.wday == 1 and month ~= 2) or (first_day.wday == 7 and last_day.day == 31) then return 6 end
  return 5
end

---@param year integer
---@param height integer
---@return string[]
function CalendarView:year(year, height)
  if height < self.header_required_height then return { tostring(year) } end

  local digits = {}
  while year ~= 0 do
    table.insert(digits, 1, year % 10)
    year = math.floor(year / 10)
  end
  local a = iter(digits):map(function(digit) return vim.split(self.digits[digit], "\n") end):fold(
    {},
    ---@param acc string[]
    ---@param splitted_digit string[]
    function(acc, splitted_digit)
      for i, _ in ipairs(splitted_digit) do
        acc[i] = (acc[i] or "") .. splitted_digit[i]
      end
      return acc
    end
  )
  return a
end

---@param month integer
---@param height integer
---@return string[]
function CalendarView:month(month, height)
  if height < self.header_required_height then return { self.months_short[month] } end
  return vim.split(self.months[month], "\n")
end

---@class EventInfo
---@field summary string
---@field start Date
---@field end Date
---@field id string
---@field is_new boolean
---@field calendar_summary string?
---@field recurrence string[]?

---@param token_info TokenInfo
---@param calendar_list CalendarList
---@param events_by_date table<string, Event>
---@param year integer
---@param month integer
---@param win integer
---@param buf integer
function CalendarView:write(token_info, calendar_list, events_by_date, year, month, win, buf)
  vim.bo[buf].modifiable = false

  local buf_name = api.nvim_buf_get_name(buf)
  local buf_year, buf_month, buf_day = buf_name:match "^calendar://day_(%d%d%d%d)_(%d%d)_(%d%d)"
  buf_year, buf_month, buf_day = tonumber(buf_year), tonumber(buf_month), tonumber(buf_day)

  local key = ("%s_%s_%s"):format(buf_year, buf_month, buf_day)
  local day_events = events_by_date[key]
  ---@type table<string, Event>
  local day_events_by_id = day_events
      and iter(day_events):fold(
        {},
        ---@param acc table<string, Event>
        ---@param event Event
        function(acc, event)
          acc[event.id] = event
          return acc
        end
      )
    or {}

  -- First line is always the number of date, don't parse it
  local lines = api.nvim_buf_get_lines(buf, 1, -1, true)

  local should_abort = false
  local diffs = {} ---@type EventDiff[]
  iter(lines)
    :map(
      ---@param line string
      ---@return EventInfo
      function(line)
        if should_abort then return end

        if line:match "^/[^ ]+" then
          local id, tail = line:match "^/([^ ]+) (.*)" ---@type string, string
          local fields = vim.split(tail, sep, { trimempty = true })
          if #fields == 1 then
            local summary = unpack(fields)

            local start_date = ("%04d-%02d-%02d"):format(buf_year, buf_month, buf_day)
            local _end_date = os.date(
              "*t",
              os.time {
                year = buf_year --[[@as integer]],
                month = buf_month --[[@as integer]],
                day = buf_day + 1,
              }
            )
            local end_date = ("%04d-%02d-%02d"):format(_end_date.year, _end_date.month, _end_date.day)
            return {
              summary = summary,
              start = {
                date = start_date,
              },
              ["end"] = {
                date = end_date,
              },
              id = id,
              is_new = false,
            }
          elseif #fields == 3 then
            local summary, start_time, end_time = unpack(fields)
            local start_date_time = ("%04d-%02d-%02dT%s%s"):format(buf_year, buf_month, buf_day, start_time, timezone)
            local end_date_time = ("%04d-%02d-%02dT%s%s"):format(buf_year, buf_month, buf_day, end_time, timezone)

            return {
              summary = summary,
              start = {
                dateTime = start_date_time,
              },
              ["end"] = {
                dateTime = end_date_time,
              },
              id = id,
              is_new = false,
            }
          else
            should_abort = true
            vim.notify(
              ("The event with id %s doens't have enoght fields to be parsed"):format(id),
              vim.log.levels.ERROR
            )
          end
        else
          local fields = vim.split(line, sep, { trimempty = true })
          if #fields == 2 then
            local summary, calendar_summary = unpack(fields)

            local start_date = ("%04d-%02d-%02d"):format(buf_year, buf_month, buf_day)
            local _end_date = os.date(
              "*t",
              os.time {
                year = buf_year --[[@as integer]],
                month = buf_month --[[@as integer]],
                day = buf_day + 1,
              }
            )
            local end_date = ("%04d-%02d-%02d"):format(_end_date.year, _end_date.month, _end_date.day)
            return {
              summary = summary,
              calendar_summary = calendar_summary,
              start = {
                date = start_date,
              },
              ["end"] = {
                date = end_date,
              },
              is_new = true,
            }
          elseif #fields == 3 then
            local summary, calendar_summary, recurrence_fields = unpack(fields)

            local recurrence = vim.split(recurrence_fields, " ")

            local start_date = ("%04d-%02d-%02d"):format(buf_year, buf_month, buf_day)
            local _end_date = os.date(
              "*t",
              os.time {
                year = buf_year --[[@as integer]],
                month = buf_month --[[@as integer]],
                day = buf_day + 1,
              }
            )
            local end_date = ("%04d-%02d-%02d"):format(_end_date.year, _end_date.month, _end_date.day)
            return {
              summary = summary,
              calendar_summary = calendar_summary,
              start = {
                date = start_date,
              },
              ["end"] = {
                date = end_date,
              },
              recurrence = recurrence,
              is_new = true,
            }
          elseif #fields == 4 then
            local summary, start_time, end_time, calendar_summary = unpack(fields)

            local start_date_time = ("%04d-%02d-%02dT%s%s"):format(buf_year, buf_month, buf_day, start_time, timezone)
            local end_date_time = ("%04d-%02d-%02dT%s%s"):format(buf_year, buf_month, buf_day, end_time, timezone)
            return {
              summary = summary,
              calendar_summary = calendar_summary,
              start = {
                dateTime = start_date_time,
              },
              ["end"] = {
                dateTime = end_date_time,
              },
              is_new = true,
            }
          elseif #fields == 5 then
            local summary, start_time, end_time, calendar_summary, recurrence_fields = unpack(fields)

            local recurrence = vim.split(recurrence_fields, " ")

            local start_date_time = ("%04d-%02d-%02dT%s%s"):format(buf_year, buf_month, buf_day, start_time, timezone)
            local end_date_time = ("%04d-%02d-%02dT%s%s"):format(buf_year, buf_month, buf_day, end_time, timezone)
            return {
              summary = summary,
              calendar_summary = calendar_summary,
              start = {
                dateTime = start_date_time,
                timeZone = text_timezone,
              },
              ["end"] = {
                dateTime = end_date_time,
                timeZone = text_timezone,
              },
              recurrence = recurrence,
              is_new = true,
            }
          else
            should_abort = true
            vim.notify(("There are not enought fields to parse the new event %s"):format(line), vim.log.levels.ERROR)
          end
        end
      end
    )
    :each(
      ---@param event_info EventInfo
      function(event_info)
        if should_abort then return end

        local is_new = event_info.is_new
        local id = event_info.id
        local summary = event_info.summary
        local recurrence = event_info.recurrence
        local calendar_summary = event_info.calendar_summary
        if not is_new then
          ---@type Event
          local cached_event = iter(day_events):find(
            ---@param event Event
            function(event) return event.id == id end
          )
          if not cached_event then
            should_abort = true
            vim.notify(
              ("The event with id `%s` is not in cache. Maybe you modified it by acciddent"):format(id),
              vim.log.levels.ERROR
            )
            return
          end

          -- to keep track of the deleted events
          day_events_by_id[cached_event.id] = nil

          local edit_diff = {}
          if cached_event.summary ~= summary then edit_diff.summary = summary end
          if
            (event_info.start.date and (event_info.start.date ~= cached_event.start.date))
            or (event_info.start.dateTime and (event_info.start.dateTime ~= cached_event.start.dateTime))
          then
            edit_diff.start = event_info.start
          end
          if
            (event_info["end"].date and (event_info["end"].date ~= cached_event["end"].date))
            or (event_info["end"].dateTime and (event_info["end"].dateTime ~= cached_event["end"].dateTime))
          then
            edit_diff["end"] = event_info["end"]
          end
          if not vim.tbl_isempty(edit_diff) then
            edit_diff.cached_event = cached_event
            edit_diff.type = "edit"
            table.insert(diffs, edit_diff)
          end
        else
          table.insert(diffs, {
            type = "new",
            summary = summary,
            calendar_summary = calendar_summary,
            recurrence = recurrence,
            start = event_info.start,
            ["end"] = event_info["end"],
          })
        end
      end
    )
  if should_abort then goto unlock end
  iter(day_events_by_id):each(
    ---@param _ string
    ---@param event Event
    function(_, event)
      table.insert(diffs, {
        type = "delete",
        cached_event = event,
      })
    end
  )

  do
    local diff_num = #diffs
    local i = 0
    local reload_if_last_diff = function()
      i = i + 1
      if i == diff_num then
        api.nvim_win_close(win, true)
        self:show(year, month)
      end
    end
    iter(diffs):each(
      ---@param diff EventDiff
      function(diff)
        if diff.type == "new" then
          local calendar = iter(calendar_list.items):find(
            function(calendar) return calendar.summary == diff.calendar_summary end
          )

          coroutine.wrap(function()
            local new_event = M.create_event(token_info, calendar.id, diff)
            table.insert(day_events, new_event)

            reload_if_last_diff()
          end)()
        elseif diff.type == "edit" then
          local calendar_id = diff.cached_event.creator.email

          coroutine.wrap(function()
            local edited_event = M.edit_event(token_info, calendar_id, diff)
            local cached_event = diff.cached_event --[[@as table<unknown, unknown>]]

            -- can't only update some fields because google checks
            -- things like the last update time to check if the
            -- event has gone out-of-sync
            for key, _ in pairs(cached_event) do
              cached_event[key] = edited_event[key]
            end

            reload_if_last_diff()
          end)()
        elseif diff.type == "delete" then
          local calendar_id = diff.cached_event.creator.email

          coroutine.wrap(function()
            M.delete_event(token_info, calendar_id, diff)
            for _, events in pairs(_cache_events) do
              for j, event in ipairs(events) do
                if event.id == diff.cached_event.id then table.remove(events, j) end
              end
            end

            reload_if_last_diff()
          end)()
        end
      end
    )
  end

  ::unlock::
  vim.bo[buf].modified = false
  vim.bo[buf].modifiable = true
end

---@param year integer
---@param month integer
---@param opts? {refresh: boolean, should_query_single_events: boolean?}
function CalendarView:show(year, month, opts)
  local has_loaded = false
  local notification ---@type number|nil
  vim.defer_fn(function()
    if has_loaded then return end

    notification = notify.add("Calendar: Loading    ", "INFO", "DiagnosticOk") ---@type number|nil
    local timer = uv.new_timer()
    local count = 1
    local loading = {
      "Calendar: Loading    ",
      "Calendar: Loading.   ",
      "Calendar: Loading..  ",
      "Calendar: Loading... ",
    }
    timer:start(
      0,
      250,
      vim.schedule_wrap(function()
        count = count + 1
        if count >= 5 then count = count - 4 end
        if notification then
          notify.update(notification, { msg = loading[count], hl = "DiagnosticOk" })
        else
          if timer:is_active() then timer:stop() end
          if not timer:is_closing() then timer:close() end
        end
      end)
    )
  end, 250)

  if not vim.tbl_isempty(self.day_bufs) then self.day_bufs = {} end
  if not vim.tbl_isempty(self.cal_bufs) then self.cal_bufs = {} end
  if not vim.tbl_isempty(self.cal_wins) then self.cal_wins = {} end

  local first_day_month = os.date("*t", os.time { year = year, month = month, day = 1 }) --[[@as osdate]]

  local w_in_m = self:w_in_m(year, month)

  local first_date ---@type osdate
  local last_date ---@type osdate

  local x_first_day_month = first_day_month.wday - 1
  if x_first_day_month <= 0 then x_first_day_month = x_first_day_month + 7 end
  do
    local i = 1
    for y = 1, w_in_m do
      for x = 1, self.d_in_w do
        i = i + 1
        local buf = api.nvim_create_buf(false, false)

        if x == 1 then self.cal_bufs[y] = {} end

        local date = os.date("*t", os.time { year = year, month = month, day = i - x_first_day_month }) --[[@as osdate]]
        if x == 1 and y == 1 then
          first_date = date
        elseif y == w_in_m and x == self.d_in_w then
          last_date = date
        end

        api.nvim_buf_set_name(buf, ("calendar://day_%04d_%02d_%02d"):format(date.year, date.month, date.day))
        self.cal_bufs[y][x] = buf
      end
    end
  end
  local last_date_plus_one =
    os.date("*t", os.time { year = last_date.year, month = last_date.month, day = last_date.day + 1 })

  coroutine.wrap(function()
    local token_info = M.get_token_info()
    assert(token_info, "There is no token_info")
    local calendar_list, maybe_new_token_info = M.get_calendar_list(token_info, {})
    token_info = maybe_new_token_info or token_info

    local start = {
      year = first_date.year --[[@as integer]],
      month = first_date.month --[[@as integer]],
      day = first_date.day --[[@as integer]],
    }
    local end_ = {
      year = last_date_plus_one.year --[[@as integer]],
      month = last_date_plus_one.month --[[@as integer]],
      day = last_date_plus_one.day --[[@as integer]],
    }
    local events_by_date = M.get_events(token_info, calendar_list, {
      start = start,
      ["end"] = end_,
      refresh = opts and opts.refresh,
      should_query_single_events = opts and opts.should_query_single_events,
    })
    -- aux = events_by_date
    has_loaded = true
    if notification then
      notify.remove(notification)
      notification = nil
    end

    local factor = 1
    -- TODO: use max_[] to make last row/col longer if needed in order to use the full screen
    local max_width = math.floor(vim.o.columns * factor)
    local max_height = math.floor(vim.o.lines * factor)

    local width = math.floor(max_width / self.d_in_w)
    local height = math.floor(max_height / (w_in_m + 1))

    local col = (vim.o.columns - max_width) / 2
    local row = (vim.o.lines - max_height) / 2

    local days_row_offset = height - 1
    local days_height = 1

    local y_m_height = height - days_height
    local y_m_width = math.floor(max_width / 2)

    self.month_buf = api.nvim_create_buf(false, false)
    api.nvim_buf_set_lines(self.month_buf, 0, -1, true, self:month(month, y_m_height))
    vim.bo[self.month_buf].modified = false
    vim.bo[self.month_buf].modifiable = false

    self.year_buf = api.nvim_create_buf(false, false)
    api.nvim_buf_set_lines(self.year_buf, 0, -1, true, self:year(year, y_m_height))
    vim.bo[self.year_buf].modified = false
    vim.bo[self.year_buf].modifiable = false

    for x = 1, self.d_in_w do
      local buf = api.nvim_create_buf(false, false)

      local w_day = x + 1
      if w_day >= 8 then w_day = w_day - 7 end
      local day_name = self.days[w_day]
      api.nvim_buf_set_lines(buf, 0, -1, true, { day_name })
      hl_enable(buf, { highlighters = { day = { pattern = day_name, group = "TODO" } } })
      vim.bo[buf].modified = false
      vim.bo[buf].modifiable = false

      self.day_bufs[x] = buf
    end

    local zindex = 1 -- less than coq documentation window
    self.month_win = api.nvim_open_win(self.month_buf, false, {
      focusable = false,
      relative = "editor",
      col = col,
      row = row,
      width = y_m_width,
      height = y_m_height,
      style = "minimal",
      zindex = zindex,
    })
    vim.wo[self.month_win].winblend = 0
    self.year_win = api.nvim_open_win(self.year_buf, false, {
      focusable = false,
      relative = "editor",
      col = col + y_m_width,
      row = row,
      width = y_m_width,
      height = y_m_height,
      style = "minimal",
      zindex = zindex,
    })
    vim.wo[self.year_win].winblend = 0

    for x = 1, self.d_in_w do
      local col_offset = (x - 1) * width
      local buf = self.day_bufs[x]
      local win = api.nvim_open_win(buf, false, {
        focusable = false,
        relative = "editor",
        col = col + col_offset,
        row = row + days_row_offset,
        width = width,
        height = days_height,
        style = "minimal",
        zindex = zindex,
      })
      vim.wo[win].winblend = 0
      self.day_wins[x] = win
    end

    for y = 1, w_in_m do
      local row_offset = y * height
      for x = 1, self.d_in_w do
        local col_offset = (x - 1) * width
        local buf = self.cal_bufs[y][x]
        local win = api.nvim_open_win(buf, false, {
          relative = "editor",
          col = col + col_offset,
          row = row + row_offset,
          width = width,
          height = height,
          style = "minimal",
          zindex = zindex,
        })
        vim.wo[win].winhighlight = "" -- since filchars eob is ' ', this will make non-focused windows a different color
        vim.wo[win].winblend = 0
        vim.wo[win].conceallevel = 3
        vim.wo[win].concealcursor = "nvic"
        if x == 1 then self.cal_wins[y] = {} end
        self.cal_wins[y][x] = win
      end
    end

    local all_bufs = iter(self.cal_bufs):flatten(1):totable()
    vim.list_extend(all_bufs, self.day_bufs)
    table.insert(all_bufs, self.month_buf)
    table.insert(all_bufs, self.year_buf)
    local all_wins = iter(self.cal_wins):flatten(1):totable()
    vim.list_extend(all_wins, self.day_wins)
    table.insert(all_wins, self.month_win)
    table.insert(all_wins, self.year_win)

    api.nvim_create_autocmd("WinClosed", {
      pattern = iter(all_wins):map(function(win) return tostring(win) end):totable(),
      callback = function()
        iter(all_bufs):each(function(buf)
          if api.nvim_buf_is_valid(buf) and api.nvim_buf_is_loaded(buf) then
            api.nvim_buf_delete(buf, { force = true })
          end
        end)
        iter(all_wins):each(function(win)
          if api.nvim_win_is_valid(win) then api.nvim_win_close(win, true) end
        end)
      end,
      once = true,
    })

    for y = 1, w_in_m do
      for x = 1, self.d_in_w do
        local buf = self.cal_bufs[y][x]
        local win = self.cal_wins[y][x]

        keymap.set("n", "<F5>", function()
          api.nvim_win_close(win, true)
          self:show(year, month, { refresh = true })
        end, { buffer = buf })
        keymap.set("n", "<Del>", function() M.calendar_list_show() end, { buffer = buf })
        keymap.set("n", "<cr>", function() M.event_show(start, end_, {}) end, { buffer = buf })
        keymap.set("n", "<", function()
          api.nvim_win_close(win, true)
          local target_year = year
          local target_month = month - 1
          if target_month == 0 then
            target_month = 12
            target_year = target_year - 1
          end
          self:show(target_year, target_month)
        end, { buffer = buf })
        keymap.set("n", ">", function()
          api.nvim_win_close(win, true)
          local target_month = month + 1
          local target_year = year
          if target_month == 13 then
            target_month = 1
            target_year = target_year + 1
          end
          self:show(target_year, target_month)
        end, { buffer = buf })

        -- TODO: somehow support count for movement keymaps
        local win_l ---@type integer
        if x - 1 >= 1 then
          win_l = self.cal_wins[y][x - 1]
        else
          win_l = self.cal_wins[y][self.d_in_w]
        end
        keymap.set("n", "<left>", function() api.nvim_set_current_win(win_l) end, { buffer = buf })
        local win_r ---@type integer
        if x + 1 <= self.d_in_w then
          win_r = self.cal_wins[y][x + 1]
        else
          win_r = self.cal_wins[y][1]
        end
        keymap.set("n", "<right>", function() api.nvim_set_current_win(win_r) end, { buffer = buf })
        local win_u ---@type integer
        if y - 1 >= 1 then
          win_u = self.cal_wins[y - 1][x]
        else
          win_u = self.cal_wins[w_in_m][x]
        end
        keymap.set("n", "<up>", function() api.nvim_set_current_win(win_u) end, { buffer = buf })
        local win_d ---@type integer
        if y + 1 <= w_in_m then
          win_d = self.cal_wins[y + 1][x]
        else
          win_d = self.cal_wins[1][x]
        end
        keymap.set("n", "<down>", function() api.nvim_set_current_win(win_d) end, { buffer = buf })

        if y == 1 and x == 1 then api.nvim_set_current_win(win) end

        api.nvim_create_autocmd("BufWriteCmd", {
          buffer = buf,
          callback = function()
            coroutine.wrap(function()
              token_info = M.get_token_info()
              assert(token_info, "There is no token_info")
              self:write(token_info, calendar_list, events_by_date, year, month, win, buf)
            end)()
          end,
        })
      end
    end

    iter(self.cal_bufs):flatten(1):each(function(cal_buf)
      local buf_name = api.nvim_buf_get_name(cal_buf)
      local buf_year, buf_month, buf_day = buf_name:match "^calendar://day_(%d%d%d%d)_(%d%d)_(%d%d)"
      buf_year, buf_month, buf_day = tonumber(buf_year), tonumber(buf_month), tonumber(buf_day)

      local day_num = ("%s"):format(buf_day)
      local lines = { day_num }

      local key = ("%s_%s_%s"):format(buf_year, buf_month, buf_day)
      local day_events = events_by_date[key]
      local highlighters = {
        conceal_id = {
          pattern = "^()/[^ ]+ ()",
          group = "", -- group needs to not be `nil` to work
          extmark_opts = {
            conceal = "",
          },
        },
        time = {
          pattern = "[ :]()%d%d()",
          group = "Number",
        },
        punctuation = {
          pattern = { sep, ":", ";", "=" },
          group = "Delimiter",
        },
      }

      local today = os.date "*t"
      if today.day == buf_day and today.month == buf_month and today.year == buf_year then
        highlighters.day = {
          pattern = "^%d+",
          group = "DiffText",
        }
      elseif buf_month == month then
        highlighters.day = {
          pattern = "^%d+",
          group = "DiffAdd",
        }
      else
        highlighters.day = {
          pattern = "^%d+",
          group = "Comment",
        }
      end
      if day_events then
        table.sort(
          day_events,
          ---@param a Event
          ---@param b Event
          function(a, b)
            if a.start.date and b.start.date then
              return a.start.date < b.start.date
            elseif a.start.date and b.start.dateTime then
              return true -- all day events first
            elseif a.start.dateTime and b.start.date then
              return false -- all day events first
            elseif a.start.dateTime and b.start.dateTime then
              return a.start.dateTime < b.start.dateTime
            end
            error "This shouldn't happen"
          end
        )
        local events_text = iter(day_events)
          :map(function(event)
            local is_recurrent = event.recurrence and not vim.tbl_isempty(event.recurrence)
            local recurrence = is_recurrent and ("%s%s"):format(sep, table.concat(event.recurrence, " ")) or ""

            if not event.start.dateTime then return ("/%s %s%s"):format(event.id, event.summary, recurrence) end
            local start_date_time = parse_date_time(event.start.dateTime)
            local end_date_time = parse_date_time(event["end"].dateTime)
            return ("/%s %s%s%02d:%02d:%02d%s%02d:%02d:%02d%s"):format(
              event.id,
              event.summary,
              sep,
              start_date_time.h,
              start_date_time.min,
              start_date_time.s,
              sep,
              end_date_time.h,
              end_date_time.min,
              end_date_time.s,
              recurrence
            )
          end)
          :totable()
        iter(day_events):each(
          ---@param event Event
          function(event)
            local pattern = "^/[^ ]+ ()" .. event.summary .. "()"

            if event.attendees then
              ---@type Attendee|nil
              local attendee = iter(event.attendees):find(
                ---@param attendee Attendee
                function(attendee)
                  -- TODO: is this true for all events?
                  return attendee.email == event.creator.email
                end
              )
              if attendee and attendee.responseStatus == "declined" then
                highlighters[event.id .. "deprecated"] = { pattern = pattern, group = "DiagnosticDeprecated" }
              end
            end

            ---@type CalendarListEntry|nil
            local calendar = iter(calendar_list.items):find(
              ---@param calendar CalendarListEntry
              function(calendar) return calendar.id == event.creator.email end
            )

            if not calendar or not event.summary then return end

            local calendar_fg = calendar.foregroundColor
            local calendar_bg = calendar.backgroundColor
            if event.creator.email ~= event.organizer.email then
              calendar_fg, calendar_bg = calendar_bg, calendar_fg
            end
            if calendar_fg then
              local fg = compute_hex_color_group(calendar_fg, "fg")
              highlighters[event.id .. "fg"] = {
                pattern = pattern,
                group = fg,
                extmark_opts = {
                  priority = 101,
                },
              }
            end
            if calendar_bg then
              local bg = compute_hex_color_group(calendar_bg, "bg")
              highlighters[event.id .. "bg"] = {
                pattern = pattern,
                group = bg,
                extmark_opts = {
                  priority = 100,
                },
              }
            end
          end
        )

        vim.list_extend(lines, events_text)
      end
      -- TODO: add support for event.colorId using `get_colors` (currently I don't have any events with custom colors, so it's no neccesary)
      hl_enable(cal_buf, { highlighters = highlighters })

      api.nvim_buf_set_lines(cal_buf, 0, -1, true, lines)
      vim.bo[cal_buf].modified = false
    end)
  end)()
end

---@class Color
---@field background string,
---@field foreground string

---@class Colors
---@field kind "calendar#colors"
---@field updated string
---@field calendar table<string, Color>
---@field event table<string, Color>

local _cache_colors ---@type Colors
-- TODO: do this for al get functions?
local is_getting_colors = false

---@async
---@param token_info TokenInfo
---@return Colors
function M.get_colors(token_info)
  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  if _cache_colors then return _cache_colors end

  local colors_received_pattern = "CalendarColorsReceived"
  api.nvim_create_autocmd("User", {
    pattern = colors_received_pattern,
    ---@param opts {data:{colors: Colors}}
    callback = function(opts)
      local ok, err = coroutine.resume(co, opts.data.colors)
      if not ok then vim.notify(err, vim.log.levels.ERROR) end
    end,
    once = true,
  })
  if is_getting_colors then return coroutine.yield() end
  is_getting_colors = true

  vim.system(
    {
      "curl",
      "--http1.1",
      "--silent",
      "--header",
      ("Authorization: Bearer %s"):format(token_info.access_token),
      "https://www.googleapis.com/calendar/v3/colors",
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)
      local ok, colors = pcall(vim.json.decode, result.stdout) ---@type boolean, string|Colors|ApiErrorResponse
      assert(ok, colors)
      ---@cast colors -string

      if colors.error then
        ---@cast colors -Colors
        assert(colors.error.status == "UNAUTHENTICATED", colors.error.message)
        coroutine.wrap(function()
          local refreshed_token_info = refresh_access_token(token_info.refresh_token)
          local new_colors = M.get_colors(refreshed_token_info)
          local err
          ok, err = coroutine.resume(co, new_colors)
          if not ok then vim.notify(err, vim.log.levels.ERROR) end
        end)()

        return
      end
      ---@cast colors +Colors
      ---@cast colors -ApiErrorResponse

      _cache_colors = colors
      is_getting_colors = false
      api.nvim_exec_autocmds("User", { pattern = colors_received_pattern, data = { colors = _cache_colors } })
    end)
  )
  return coroutine.yield()
end

---@class EventDiff
---@field type "new"|"edit"|"delete"
---@field summary string?
---@field recurrence string[]?
---@field start Date?
---@field end Date?
---@field reminders Reminders?
---@field description string?
---@field cached_event Event?
---@field calendar_summary string?

---@class CalendarDiff
---@field type "new"|"edit"|"delete"
---@field summary string?
---@field cached_calendar Calendar?

---@async
---@param token_info TokenInfo
---@param diff EventDiff
---@return Event
function M.create_event(token_info, calendar_id, diff)
  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  local data =
    vim.json.encode { start = diff.start, ["end"] = diff["end"], summary = diff.summary, recurrence = diff.recurrence }
  local tmp_name = os.tmpname()
  local tmp_file = io.open(tmp_name, "w")
  assert(tmp_file)
  tmp_file:write(data)
  tmp_file:close()

  vim.system(
    {
      "curl",
      "--data-binary",
      ("@%s"):format(tmp_name),
      "--http1.1",
      "--silent",
      "--header",
      ("Authorization: Bearer %s"):format(token_info.access_token),
      ("https://www.googleapis.com/calendar/v3/calendars/%s/events"):format(url_encode(calendar_id)),
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)
      local ok, new_event = pcall(vim.json.decode, result.stdout) ---@type boolean, string|Event|ApiErrorResponse
      assert(ok, new_event)
      ---@cast new_event -string

      if new_event.error then
        ---@cast new_event -Event
        assert(new_event.error.status == "UNAUTHENTICATED", new_event.error.message)
        coroutine.wrap(function()
          local refreshed_token_info = refresh_access_token(token_info.refresh_token)
          local new_new_event = M.create_event(refreshed_token_info, calendar_id, diff)
          local err
          ok, err = coroutine.resume(co, new_new_event)
          if not ok then vim.notify(err, vim.log.levels.ERROR) end
        end)()
        return
      end
      ---@cast new_event +Event
      ---@cast new_event -ApiErrorResponse

      local err
      ok, err = coroutine.resume(co, new_event)
      if not ok then vim.notify(err, vim.log.levels.ERROR) end
    end)
  )
  return coroutine.yield()
end

---@async
---@param token_info TokenInfo
---@param diff EventDiff
---@return Event
function M.edit_event(token_info, calendar_id, diff)
  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  local cached_event = vim.deepcopy(diff.cached_event) --[[@as Event]]
  if diff.summary then cached_event.summary = diff.summary end
  if diff.recurrence then cached_event.recurrence = diff.recurrence end
  if diff.start then cached_event.start = diff.start end
  if diff["end"] then cached_event["end"] = diff["end"] end
  if diff.reminders then cached_event.reminders = diff.reminders end
  if diff.description then cached_event.description = diff.description end
  local data = vim.json.encode(cached_event)
  local tmp_name = os.tmpname()
  local tmp_file = io.open(tmp_name, "w")
  assert(tmp_file)
  tmp_file:write(data)
  tmp_file:close()

  vim.system(
    {
      "curl",
      "--request",
      "PUT",
      "--data-binary",
      ("@%s"):format(tmp_name),
      "--http1.1",
      "--silent",
      "--header",
      ("Authorization: Bearer %s"):format(token_info.access_token),
      ("https://www.googleapis.com/calendar/v3/calendars/%s/events/%s"):format(
        url_encode(calendar_id),
        url_encode(diff.cached_event.id)
      ),
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)
      local ok, edited_event = pcall(vim.json.decode, result.stdout) ---@type boolean, string|Event|ApiErrorResponse
      assert(ok, edited_event)
      ---@cast edited_event -string

      if edited_event.error then
        ---@cast edited_event -Event
        assert(edited_event.error.status == "UNAUTHENTICATED", edited_event.error.message)
        coroutine.wrap(function()
          local refreshed_token_info = refresh_access_token(token_info.refresh_token)
          local new_edited_event = M.edit_event(refreshed_token_info, calendar_id, diff)
          local err
          ok, err = coroutine.resume(co, new_edited_event)
          if not ok then vim.notify(err, vim.log.levels.ERROR) end
        end)()
        return
      end
      ---@cast edited_event +Event
      ---@cast edited_event -ApiErrorResponse

      local err
      ok, err = coroutine.resume(co, edited_event)
      if not ok then vim.notify(err, vim.log.levels.ERROR) end
    end)
  )
  return coroutine.yield()
end

---@async
---@param token_info TokenInfo
---@param calendar_id string
---@param diff EventDiff
function M.delete_event(token_info, calendar_id, diff)
  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  vim.system(
    {
      "curl",
      "--request",
      "DELETE",
      "--http1.1",
      "--silent",
      "--header",
      ("Authorization: Bearer %s"):format(token_info.access_token),
      ("https://www.googleapis.com/calendar/v3/calendars/%s/events/%s"):format(
        url_encode(calendar_id),
        url_encode(diff.cached_event.id)
      ),
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)

      if result.stdout == "" then
        local ok, err = coroutine.resume(co)
        if not ok then vim.notify(err, vim.log.levels.ERROR) end
        return
      end

      local ok, response = pcall(vim.json.decode, result.stdout) ---@type boolean, string|ApiErrorResponse
      assert(ok, response)
      ---@cast response -string

      if response.error then
        ---@cast response -Event
        assert(response.error.status == "UNAUTHENTICATED", response.error.message)
        coroutine.wrap(function()
          local refreshed_token_info = refresh_access_token(token_info.refresh_token)
          M.delete_event(refreshed_token_info, calendar_id, diff)
          local err
          ok, err = coroutine.resume(co)
          if not ok then vim.notify(err, vim.log.levels.ERROR) end
        end)()
        return
      end
    end)
  )
  coroutine.yield()
end

function M.add_coq_completion()
  COQsources = COQsources or {} ---@type coq_sources
  COQsources[new_uid(COQsources)] = {
    name = "CL",
    fn = function(args, cb)
      local buf_name = api.nvim_buf_get_name(0)
      if not buf_name:match "^calendar://" then return cb() end
      if args.line:match "^/[^ ]+ " then return cb() end

      local fields = vim.split(args.line, sep, { trimempty = true })
      local _, sep_num = args.line:gsub(sep, "")
      -- TODO: increase maximum?
      if sep_num == 0 or sep_num > 4 then return cb() end

      local recurrence_field = (fields[3] and fields[3]:match "^%d") and (fields[5] or "") or (fields[3] or "")
      local current_propertie = recurrence_field:match "(%w+):[^ ]*$"
      local current_rule = recurrence_field:match "(%w+)=[^=; ]*$"

      if sep_num == 1 or sep_num == 3 then
        coroutine.wrap(function()
          local token_info = M.get_token_info()
          assert(token_info, "There is no token_info")
          local calendar_list = M.get_calendar_list(token_info, {})

          local items = iter(calendar_list.items)
            :filter(
              ---@param calendar CalendarListEntry
              function(calendar) return calendar.accessRole ~= "reader" end
            )
            :map(
              ---@param calendar CalendarListEntry
              function(calendar)
                return {
                  label = calendar.summary,
                  documentation = calendar.description, -- TODO: maybe change this to `detail`?
                  kind = vim.lsp.protocol.CompletionItemKind.EnumMember,
                }
              end
            )
            :totable()
          cb { isIncomplete = false, items = items }
        end)()
      elseif (sep_num == 2 or sep_num == 4) and not current_propertie then
        local properties = {} ---@type string[]
        if not recurrence_field:match "RRULE" then table.insert(properties, "RRULE") end
        if not recurrence_field:match "RDATE" then table.insert(properties, "RDATE") end
        if not recurrence_field:match "EXDATE" then table.insert(properties, "EXDATE") end
        cb {
          isIncomplete = false,
          items = iter(properties)
            :map(function(field) return { label = field, kind = vim.lsp.protocol.CompletionItemKind.EnumMember } end)
            :totable(),
        }
      elseif (sep_num == 2 or sep_num == 4) and current_propertie == "RRULE" and not current_rule then
        local rules = {} ---@type {[1]: string, [2]: string}[]
        if not recurrence_field:match "FREQ" then
          table.insert(rules, {
            "FREQ",
            "Identifies the type of recurrence rule. This rule part **MUST** be specified in the recurrence rule. Valid values include SECONDLY, to specify repeating events based on an interval of a second or more; MINUTELY, to specify repeating events based on an interval of a minute or more; HOURLY, to specify repeating events based on an interval of an hour or more; DAILY, to specify repeating events based on an interval of a day or more; WEEKLY, to specify repeating events based on an interval of a week or more; MONTHLY, to specify repeating events based on an interval of a month or more; and YEARLY, to specify repeating events based on an interval of a year or more.",
          })
        end
        -- TODO:  remove until because it depends on the end date? I guess I would need a new field for the end date
        if not recurrence_field:match "COUNT" and not recurrence_field:match "UNTIL" then
          table.insert(rules, {
            "COUNT",
            'Defines the number of occurrences at which to range-bound the recurrence. The "DTSTART" property value always counts as the first occurrence. ',
          })
          table.insert(rules, {
            "UNTIL",
            'Defines a DATE or DATE-TIME value that bounds the recurrence rule in an inclusive manner. If the value specified by UNTIL is synchronized with the specified recurrence, this DATE or DATE-TIME becomes the last instance of the recurrence. The value of the UNTIL rule part **MUST** have the same value type as the "DTSTART" property. Furthermore, if the "DTSTART" property is specified as a date with local time, then the UNTIL rule part **MUST** also be specified as a date with local time. If the "DTSTART" property is specified as a date with UTC time or a date with local time and time zone reference, then the UNTIL rule part **MUST** be specified as a date with UTC time. In the case of the "STANDARD" and "DAYLIGHT" sub-components the UNTIL rule part **MUST** always be specified as a date with UTC time. If specified as a DATE-TIME value, then it **MUST** be specified in a UTC time format. If not present, and the COUNT rule part is also not present, the "RRULE" is considered to repeat forever. ',
          })
        end
        if not recurrence_field:match "INTERVAL" then
          table.insert(rules, {
            "INTERVAL",
            'Contains a positive integer representing at which intervals the recurrence rule repeats. The default value is "1", meaning every second for a **SECONDLY** rule, every minute for a **MINUTELY** rule, every hour for an **HOURLY** rule, every day for a **DAILY** rule, every week for a **WEEKLY** rule, every month for a **MONTHLY** rule, and every year for a **YEARLY** rule. For example, within a **DAILY** rule, a value of "8" means every eight days. ',
          })
        end
        if not recurrence_field:match "BYSECOND" then
          table.insert(rules, {
            "BYSECOND",
            'Specifies a COMMA-separated list of seconds within a minute. Valid values are 0 to 60. The BYSECOND, BYMINUTE and BYHOUR rule parts **MUST NOT** be specified when the associated "DTSTART" property has a DATE value type. These rule parts **MUST** be ignored in RECUR value that violate the above requirement (e.g., generated by applications that pre-date this revision of iCalendar).',
          })
        end
        if not recurrence_field:match "BYMINUTE" then
          table.insert(rules, {
            "BYMINUTE",
            'The BYMINUTE rule part specifies a COMMA-separated list of minutes within an hour. Valid values are 0 to 59. The BYSECOND, BYMINUTE and BYHOUR rule parts **MUST NOT** be specified when the associated "DTSTART" property has a DATE value type. These rule parts **MUST** be ignored in RECUR value that violate the above requirement (e.g., generated by applications that pre-date this revision of iCalendar).',
          })
        end
        if not recurrence_field:match "BYHOUR" then
          table.insert(rules, {
            "BYHOUR",
            'The BYHOUR rule part specifies a COMMA- separated list of hours of the day. Valid values are 0 to 23. The BYSECOND, BYMINUTE and BYHOUR rule parts **MUST NOT** be specified when the associated "DTSTART" property has a DATE value type. These rule parts **MUST** be ignored in RECUR value that violate the above requirement (e.g., generated by applications that pre-date this revision of iCalendar).',
          })
        end
        if not recurrence_field:match "BYDAY" then
          table.insert(rules, {
            "BYDAY",
            'Specifies a COMMA-separated list of days of the week; SU indicates Sunday; MO indicates Monday; TU indicates Tuesday; WE indicates Wednesday; TH indicates Thursday; FR indicates Friday; and SA indicates Saturday.\n\nEach BYDAY value can also be preceded by a positive (+n) or negative (-n) integer. If present, this indicates the nth occurrence of a specific day within the MONTHLY or YEARLY "RRULE". ',
          })
        end
        if not recurrence_field:match "BYMONTHDAY" then
          table.insert(rules, {
            "BYMONTHDAY",
            "Specifies a COMMA-separated list of days of the month. Valid values are 1 to 31 or -31 to -1. For example, -10 represents the tenth to the last day of the month. The BYMONTHDAY rule part **MUST NOT** be specified when the FREQ rule part is set to WEEKLY. ",
          })
        end
        if not recurrence_field:match "BYYEARDAY" then
          table.insert(rules, {
            "BYYEARDAY",
            "Specifies a COMMA-separated list of days of the year. Valid values are 1 to 366 or -366 to -1. For example, -1 represents the last day of the year (December 31st) and -306 represents the 306th to the last day of the year (March 1st). The BYYEARDAY rule part **MUST NOT** be specified when the FREQ rule part is set to DAILY, WEEKLY, or MONTHLY. ",
          })
        end
        if not recurrence_field:match "BYWEEKNO" then
          table.insert(rules, {
            "BYWEEKNO",
            "Specifies a COMMA-separated list of ordinals specifying weeks of the year. Valid values are 1 to 53 or -53 to -1. This corresponds to weeks according to week numbering as defined in [ISO.8601.2004]. A week is defined as a seven day period, starting on the day of the week defined to be the week start (see WKST). Week number one of the calendar year is the first week that contains at least four (4) days in that calendar year. This rule part **MUST NOT** be used when the FREQ rule part is set to anything other than YEARLY. For example, 3 represents the third week of the year. ",
          })
        end
        if not recurrence_field:match "BYMONTH" then
          table.insert(
            rules,
            { "BYMONTH", "Specifies a COMMA-separated list of months of the year.  Valid values are 1 to 12. " }
          )
        end
        if not recurrence_field:match "BYSETPOS" then
          table.insert(rules, {
            "BYSETPOS",
            'Specifies a COMMA-separated list of values that corresponds to the nth occurrence within the set of recurrence instances specified by the rule. BYSETPOS operates on a set of recurrence instances in one interval of the recurrence rule. For example, in a WEEKLY rule, the interval would be one week A set of recurrence instances starts at the beginning of the interval defined by the FREQ rule part. Valid values are 1 to 366 or -366 to -1. It **MUST** only be used in conjunction with another BYxxx rule part. For example "the last work day of the month" could be represented as:\n\nFREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-1\n\nEach BYSETPOS value can include a positive (+n) or negative (-n) integer. If present, this indicates the nth occurrence of the specific occurrence within the set of occurrences specified by the rule. ',
          })
        end
        if not recurrence_field:match "WKST" then
          table.insert(rules, {
            "WKST",
            'Specifies the day on which the workweek starts. Valid values are MO, TU, WE, TH, FR, SA, and SU. This is significant when a WEEKLY "RRULE" has an interval greater than 1, and a BYDAY rule part is specified. This is also significant when in a YEARLY "RRULE" when a BYWEEKNO rule part is specified. The default value is MO. ',
          })
        end
        cb {
          isIncomplete = false,
          items = iter(rules)
            :map(
              function(rule)
                return {
                  label = rule[1],
                  documentation = rule[2],
                  kind = vim.lsp.protocol.CompletionItemKind.EnumMember,
                }
              end
            )
            :totable(),
        }
      elseif (sep_num == 2 or sep_num == 4) and current_propertie == "RRULE" and current_rule then
        local options = {
          FREQ = {
            "SECONDLY",
            "MINUTELY",
            "HOURLY",
            "DAILY",
            "WEEKLY",
            "MONTHLY",
            "YEARLY",
          },
          BYDAY = {
            "SU",
            "MO",
            "TU",
            "WE",
            "TH",
            "FR",
            "SA",
          },
        }
        if not options[current_rule] then return cb() end
        cb {
          isIncomplete = false,
          items = iter(options[current_rule])
            :map(function(option) return { label = option, kind = vim.lsp.protocol.CompletionItemKind.EnumMember } end)
            :totable(),
        }
      else
        cb()
      end
    end,
  }
end

-- TODO: remove this cache? I don't think having two caches is a great idea.
-- Maybe use this only for recurring events?
local _cache_event = {} ---@type table<string, Event> recurringEventId -> Event

---@async
---@param token_info TokenInfo
---@param calendar_id string
---@param id string
---@param opts {refresh: boolean?}
---@return Event, TokenInfo|nil
function M.get_event(token_info, calendar_id, id, opts)
  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  if _cache_event[id] then return _cache_event[id] end

  if opts.refresh then _cache_event = {} end

  vim.system(
    {
      "curl",
      "--http1.1",
      "--silent",
      "--header",
      ("Authorization: Bearer %s"):format(token_info.access_token),
      ("https://www.googleapis.com/calendar/v3/calendars/%s/events/%s"):format(url_encode(calendar_id), url_encode(id)),
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)
      local ok, event = pcall(vim.json.decode, result.stdout) ---@type boolean, string|Event|ApiErrorResponse
      assert(ok, event)
      ---@cast event -string

      if event.error then
        ---@cast event -Event
        assert(event.error.status == "UNAUTHENTICATED", event.error.message)
        coroutine.wrap(function()
          local refreshed_token_info = refresh_access_token(token_info.refresh_token)
          local new_event = M.get_event(refreshed_token_info, calendar_id, id, opts)
          _cache_event[id] = new_event
          local err
          ok, err = coroutine.resume(co, new_event, refreshed_token_info)
          if not ok then vim.notify(err, vim.log.levels.ERROR) end
        end)()
        return
      end
      ---@cast event +Event
      ---@cast event -ApiErrorResponse

      _cache_event[id] = event
      local err
      ok, err = coroutine.resume(co, event, nil)
      if not ok then vim.notify(err, vim.log.levels.ERROR) end
    end)
  )
  return coroutine.yield()
end

---@async
---@param buf integer
---@param win integer
---@param month_start CalendarDate
---@param month_end CalendarDate
local function event_write(buf, win, month_start, month_end)
  local lines = api.nvim_buf_get_lines(buf, 0, -1, true)

  local id = api.nvim_buf_get_name(buf):match "^calendar://event_(.*)"
  local cached_event = _cache_event[id]
  local calendar_id = cached_event.creator.email

  if #lines == 1 and lines[1] == "" then
    local token_info = M.get_token_info()
    assert(token_info, "There is no token_info")
    M.delete_event(token_info, calendar_id, { type = "delete", cached_event = cached_event })
    api.nvim_win_close(win, true)
    return
  end

  local summary = lines[1]:match "^summary: (.*)"
  local recurrence = vim.split(lines[2]:match "^recurrence: (.*)", " ")
  local duration = vim.split(lines[3]:match "^duration: (.*)", sep)

  local start = {} ---@type Date
  local end_ = {} ---@type Date
  if lines[3]:match "T" then
    start.dateTime = duration[1]
    start.timeZone = cached_event.start.timeZone
    end_.dateTime = duration[2]
    end_.timeZone = cached_event["end"].timeZone
  else
    start.date = duration[1]
    end_.date = duration[1]
  end

  local default, override = lines[4]:match "^reminders: ([^ |]*) | (.*)"
  local overrides = vim.split(override, sep)
  local reminders = {
    useDefault = default == "default",
    overrides = iter(overrides)
      :map(
        ---@param o string
        function(o)
          if o == "" then return end
          local minutes, method = o:match "^(%d+) min : (.*)"
          return { minutes = minutes, method = method }
        end
      )
      :totable(),
  }
  if vim.tbl_isempty(reminders.overrides) then reminders.overrides = nil end
  local description ---@type string|nil
  if lines[5] then description = table.concat(vim.list_slice(lines, 6), "\n") end

  local token_info = M.get_token_info()
  assert(token_info, "There is no token_info")

  local new_event = M.edit_event(token_info, calendar_id, {
    type = "edit",
    cached_event = cached_event,
    summary = summary,
    recurrence = recurrence,
    start = start,
    ["end"] = end_,
    reminders = reminders,
    description = description,
  })
  _cache_event[id] = new_event

  api.nvim_win_close(win, true)
  M.event_show(month_start, month_end, {})
end

---@param start CalendarDate
---@param end_ CalendarDate
---@param opts {refresh: boolean?}
function M.event_show(start, end_, opts)
  coroutine.wrap(function()
    local line = api.nvim_get_current_line()
    if not line:match "^/[^ ]+" then return end

    local token_info = M.get_token_info()
    assert(token_info, "There is no token_info")
    local calendar_list, maybe_new_token_info = M.get_calendar_list(token_info, {})
    token_info = maybe_new_token_info or token_info
    local events_by_date = M.get_events(token_info, calendar_list, {
      start = start,
      ["end"] = end_,
    })

    local event_id = line:match "^/([^ ]+)" ---@type string
    local events = iter(events_by_date)
      :map(
        ---@param _k string
        ---@param events Event[]
        function(_k, events) return events end
      )
      :totable()
    ---@type Event
    local event = iter(events):flatten(1):find(
      ---@param event Event
      function(event) return event.id == event_id end
    )
    assert(event, ("There is no event with id %s"):format(event_id))
    if not event.recurringEventId then return end

    ---@type Calendar
    local calendar = iter(calendar_list.items):find(
      ---@param calendar CalendarListEntry
      function(calendar) return calendar.id == event.creator.email end
    )
    assert(calendar, ("There is no calendar for event %s"):format(event_id))

    local recurring_event = M.get_event(token_info, calendar.id, event.recurringEventId, opts)

    local is_recurrent = recurring_event.recurrence and not vim.tbl_isempty(recurring_event.recurrence)
    local recurrence = is_recurrent and table.concat(recurring_event.recurrence, " ") or ""
    local _start = recurring_event.start.date or recurring_event.start.dateTime
    local _end = recurring_event["end"].date or recurring_event["end"].dateTime
    local reminders = ("%s%s%s"):format(
      recurring_event.reminders.useDefault and "default" or "nodefault",
      sep,
      iter(recurring_event.reminders.overrides or {})
        :map(function(o) return ("%s min : %s"):format(o.minutes, o.method) end)
        :join(sep)
    )

    local buf = api.nvim_create_buf(false, false)
    api.nvim_buf_set_name(buf, ("calendar://event_%s"):format(event.recurringEventId)) -- TODO: always use recurringEventId?
    api.nvim_create_autocmd("BufLeave", {
      buffer = buf,
      callback = function() api.nvim_buf_delete(buf, { force = true }) end,
      once = true,
    })
    hl_enable(buf, {
      highlighters = {
        keywords = {
          pattern = "^()%l+():",
          group = "Keyword",
        },
        punctuation = {
          pattern = { ";", "=", ",", sep },
          group = "Delimiter",
        },
        number = {
          pattern = "%d",
          group = "Number",
        },
        sign = {
          pattern = "()[+-]()%d%d:%d%d",
          group = "Delimiter",
        },
      },
    })

    local lines = recurring_event.description and vim.split(recurring_event.description, "\n") or {}
    lines = vim.list_extend({
      ("summary: %s"):format(recurring_event.summary),
      ("recurrence: %s"):format(recurrence),
      ("duration: %s | %s"):format(_start, _end),
      ("reminders: %s"):format(reminders),
      "description:",
    }, lines)
    api.nvim_buf_set_lines(buf, 0, -1, true, lines)

    local factor = 0.85
    local width = math.floor(vim.o.columns * factor)
    local height = math.floor(vim.o.lines * factor)
    local col = (vim.o.columns - width) / 2
    local row = (vim.o.lines - height) / 2
    local win = api.nvim_open_win(buf, true, {
      relative = "editor",
      row = row,
      col = col,
      width = width,
      height = height,
      title = " Calendar list ",
      border = "single",
      style = "minimal",
    })
    api.nvim_create_autocmd("BufWriteCmd", {
      buffer = buf,
      callback = function()
        coroutine.wrap(function() event_write(buf, win, start, end_) end)()
      end,
    })
    keymap.set("n", "<F5>", function()
      api.nvim_win_close(win, true)
      M.event_show(start, end_, { refresh = true })
    end, { buffer = buf })
  end)()
end

M.CalendarView = CalendarView

return M
