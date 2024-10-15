-- based on https://github.com/itchyny/calendar.vim

-- TODO: maybe change asserts to vim.notify errors (?)
-- TODO: maybe show notifications (maybe using mini.notify(to show progress)) while loading/waiting for responses (?)
local uv = vim.uv
local api = vim.api
local keymap = vim.keymap
local iter = vim.iter
local compute_hex_color_group = require("mini.hipatterns").compute_hex_color_group
local hl_enable = require("mini.hipatterns").enable
local fs_exists = require("personal.util.general").fs_exists
local new_uid = require("personal.util.general").new_uid

local M = {}

local api_key = vim.env.GOOGLE_CALENDAR_API_KEY ---@type string
local client_id = vim.env.GOOGLE_CALENDAR_CLIENT_ID ---@type string
local client_secret = vim.env.GOOGLE_CALENDAR_CLIENT_SECRET ---@type string

local data_path = ("%s/%s"):format(vim.fn.stdpath "data", "/calendar")
data_path = vim.fs.normalize(data_path)

local _timezone1, _timezone2 = tostring(os.date "%z"):match "([-+]%d%d)(%d%d)"
local timezone = ("%s:%s"):format(_timezone1, _timezone2)

---@param c string
---@return string
local char_to_hex = function(c) return string.format("%%%02X", string.byte(c)) end

---@param url string
---@return string|nil
local function url_encode(url)
  if url == nil then return end
  url = url:gsub("\n", "\r\n")
  -- maybe use this instead of line below (?)
  -- url = url:gsub("([^%w _%%%-%.~])", char_to_hex)
  url = url:gsub("([^%w ])", char_to_hex)
  url = url:gsub(" ", "+")
  return url
end

---@param x string
---@return string
local hex_to_char = function(x) return string.char(tonumber(x, 16)) end

---@param url string
---@return string|nil
local urldecode = function(url)
  if url == nil then return end
  url = url:gsub("+", " ")
  url = url:gsub("%%(%x%x)", hex_to_char)
  return url
end

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

---@param refresh_token string
---@param cb fun(token_info: TokenInfo)
local function refresh_access_token(refresh_token, cb)
  local token_refreshed_pattern = "CalendarAccessTokenRefreshed"
  api.nvim_create_autocmd("User", {
    pattern = token_refreshed_pattern,
    ---@param opts {data:{token_info: TokenInfo}}
    callback = function(opts) cb(opts.data.token_info) end,
    once = true,
  })
  if is_refreshing_access_token then return end
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

        M.get_token_info(function(token_info)
          is_refreshing_access_token = false
          api.nvim_exec_autocmds("User", { pattern = token_refreshed_pattern, data = { token_info = token_info } })
        end)

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

---@param cb fun(token_info: TokenInfo)
function M.get_token_info(cb)
  if _cache_token_info then
    cb(_cache_token_info)
    return
  end

  fs_exists(
    refresh_token_path,
    vim.schedule_wrap(function(exists, err)
      if exists == nil and err then
        vim.notify(err, vim.log.levels.ERROR)
        return
      end
      if exists then
        local file = io.open(refresh_token_path, "r")
        assert(file)
        local content = file:read "*a"
        file:close()

        local ok, token_info = pcall(vim.json.decode, content) ---@type boolean, string|TokenInfo
        assert(ok, token_info)
        ---@cast token_info -string

        _cache_token_info = token_info
        cb(token_info)
        return
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
            -- TODO: is this needed?
            -- "--no-buffer",
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
            cb(token_info)
          end)
        end,
      }
    end)
  )
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
---@field backgroundColor string
---@field foregroundColor string
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

local _cache_calendar_list ---@type CalendarList

---@param token_info TokenInfo
---@param cb fun(calendar_list: CalendarList)
function M.get_calendar_list(token_info, cb)
  -- TODO: automatically or manually invalidate/reload this?
  if _cache_calendar_list then
    cb(_cache_calendar_list)
    return
  end

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
        refresh_access_token(
          token_info.refresh_token,
          function(refreshed_token_info) M.get_calendar_list(refreshed_token_info, cb) end
        )
        return
      end
      ---@cast calendar_list +CalendarList
      ---@cast calendar_list -ApiErrorResponse

      _cache_calendar_list = calendar_list
      cb(calendar_list)
    end)
  )
end

local ns = api.nvim_create_namespace "Calendar"

local sep = " | "
function M.calendar_list_show()
  M.get_token_info(function(token_info)
    M.get_calendar_list(token_info, function(calendar_list)
      local buf = api.nvim_create_buf(false, false)
      api.nvim_buf_set_name(buf, "calendar://calendar_list")
      api.nvim_create_autocmd("BufLeave", {
        buffer = buf,
        callback = function() api.nvim_buf_delete(buf, { force = true }) end,
        once = true,
      })
      api.nvim_create_autocmd("BufWriteCmd", {
        buffer = buf,
        callback = function()
          vim.bo[buf].modifiable = false

          local lines = api.nvim_buf_get_lines(buf, 0, -1, true)

          iter(lines)
            :map(function(line)
              local summary, description, id = unpack(vim.split(line, sep, { trimempty = true }))
              return {
                summary = summary,
                description = description,
                id = id,
              }
            end)
            :each(function(calendar_info)
              -- TODO: fist parse all the diffs and then CRUD
              -- if not calendar_info.id then print(("Creating calendar with name %s"):format(calendar_info.summary)) end
            end)

          vim.bo[buf].modified = false
          vim.bo[buf].modifiable = true
        end,
      })
      iter(ipairs(calendar_list.items)):each(
        ---@param i integer
        ---@param calendar CalendarListEntry
        function(i, calendar)
          local row = i - 1
          local line = ("%s%s%s%s%s"):format(
            calendar.summary,
            sep,
            calendar.description or "[No description]",
            sep,
            calendar.id
          )
          -- first line replaces empty line
          -- all other lines are inserted at the end of the buf
          api.nvim_buf_set_lines(buf, row, row == 0 and row + 1 or row, true, { line })
          local bg = compute_hex_color_group(calendar.backgroundColor, "bg")
          local fg = compute_hex_color_group(calendar.foregroundColor, "fg")
          api.nvim_buf_set_extmark(buf, ns, row, 0, {
            end_col = #calendar.summary,
            hl_group = bg,
          })
          api.nvim_buf_set_extmark(buf, ns, row, 0, {
            end_col = #calendar.summary,
            hl_group = fg,
          })
        end
      )

      keymap.set("n", "<cr>", function()
        local line = api.nvim_get_current_line()
        local _, _, id = unpack(vim.split(line, sep, { trimempty = true }))

        api.nvim_win_close(0, true)
        M.calendar_show(id)
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
        title = " Calendar list ",
        border = "single",
        style = "minimal",
      })
    end)
  end)
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

---@param token_info TokenInfo
---@param id string
---@param cb fun(calendar: Calendar)
function M.get_calendar(token_info, id, cb)
  if _cache_calendar[id] then
    cb(_cache_calendar[id])
    return
  end

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
        refresh_access_token(
          token_info.refresh_token,
          function(refreshed_token_info) M.get_calendar(refreshed_token_info, id, cb) end
        )
        return
      end
      ---@cast calendar +Calendar
      ---@cast calendar -ApiErrorResponse

      _cache_calendar[id] = calendar
      cb(calendar)
    end)
  )
end

---@param id string
function M.calendar_show(id)
  M.get_token_info(function(token_info)
    M.get_calendar(token_info, id, function(calendar)
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
    end)
  end)
end

---@class User
---@field id string
---@field email string
---@field displayName string
---@field self boolean

---@class Atendee: User
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
---@field attendees Atendee[]
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

local _cache_events = {} ---@type table<string, Event[]> year_month -> events

---@param token_info TokenInfo
---@param calendar_list CalendarList
---@param year integer
---@param month integer
---@param opts? {refresh: boolean}
---@param cb fun(events: Event[])
function M.get_events(token_info, calendar_list, year, month, opts, cb)
  if opts and opts.refresh then _cache_events = {} end

  local start_year = year
  local start_month = month
  local end_year = year
  local end_month = month + 1
  if end_month > 12 then
    end_year = end_year + 1
    end_month = end_month - 12
  end

  local time_min = ("%04d-%02d-01T00:00:00%s"):format(start_year, start_month, timezone)
  local time_max = ("%04d-%02d-01T00:00:00%s"):format(end_year, end_month, timezone)

  local key = ("%s_%s"):format(year, month)
  if _cache_events[key] then
    cb(_cache_events[key])
    return
  end

  local all_calendar_events = {} ---@type CalendarEvents[]

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
          ("https://www.googleapis.com/calendar/v3/calendars/%s/events?timeMin=%s&timeMax=%s&singleEvents=true"):format(
            url_encode(calendar.id),
            url_encode(time_min),
            url_encode(time_max)
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
            refresh_access_token(
              token_info.refresh_token,
              function(refreshed_token_info) M.get_events(refreshed_token_info, calendar_list, year, month, opts, cb) end
            )
            return
          end
          ---@cast events +CalendarEvents
          ---@cast events -ApiErrorResponse

          table.insert(all_calendar_events, events)

          if #all_calendar_events == #calendar_list.items then
            _cache_events[key] = iter(all_calendar_events)
              :map(function(calendar_event) return calendar_event.items end)
              :flatten(1)
              :totable()
            cb(_cache_events[key])
          end
        end)
      )
    end
  )
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

---@param token_info TokenInfo
---@param calendar_list CalendarList
---@param events_by_date table<string, Event>
---@param year integer
---@param month integer
---@param win integer
---@param buf integer
function CalendarView:write(token_info, calendar_list, events_by_date, year, month, win, buf)
  vim.bo[buf].modifiable = false

  -- First line is always the number of date, don't parse it
  local lines = api.nvim_buf_get_lines(buf, 1, -1, true)

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

  local diffs = {} ---@type Diff[]
  for _, line in ipairs(lines) do
    if line:match "^/[^ ]+" then -- existing entry
      local id, tail = line:match "^/([^ ]+) (.*)" ---@type string, string
      local summary, start_time, end_time = unpack(vim.split(tail, sep, { trimempty = true }))

      local month_events = _cache_events[("%s_%s"):format(year, month)]
      ---@type Event
      local cached_event = iter(month_events):find(
        ---@param event Event
        function(event) return event.id == id end
      )
      assert(cached_event, ("The event with id `%s` is not in cache. Maybe you modified it by acciddent"):format(id))
      assert(summary, ("The event with id `%s` has no summary"):format(id))

      -- to keep track of the deleted events
      day_events_by_id[cached_event.id] = nil

      -- TODO: maybe clone event if id is the same but name is different from existing one and existing one is still in buffer (?)
      -- maybe don't support cloning?

      local edit_diff = {}
      if cached_event.summary ~= summary then edit_diff.summary = summary end
      local start_date = ("%04d-%02d-%02d"):format(buf_year, buf_month, buf_day)
      local end_date = ("%04d-%02d-%02d"):format(buf_year, buf_month, buf_day + 1)
      local start_date_time = ("%04d-%02d-%02dT%s%s"):format(buf_year, buf_month, buf_day, start_time, timezone)
      local end_date_time = ("%04d-%02d-%02dT%s%s"):format(buf_year, buf_month, buf_day, end_time, timezone)
      if
        (not start_time or not end_time)
        and (start_date ~= cached_event.start.date or end_date ~= cached_event["end"].date)
      then
        edit_diff.start = {
          date = start_date,
        }
        edit_diff["end"] = {
          date = end_date,
        }
      elseif
        start_time
        and end_time
        and (start_date_time ~= cached_event.start.dateTime or end_date_time ~= cached_event["end"].dateTime)
      then
        edit_diff.start = {
          dateTime = start_date_time,
        }
        edit_diff["end"] = {
          dateTime = end_date_time,
        }
      end
      if not vim.tbl_isempty(edit_diff) then
        edit_diff.cached_event = cached_event
        edit_diff.type = "edit"
        table.insert(diffs, edit_diff)
      end
    else -- new entry
      local summary, start_time, end_time, calendar_summary = unpack(vim.split(line, sep, { trimempty = true }))
      assert(summary ~= "", "The summary for a new event is empty")

      local start_date = ("%04d-%02d-%02d"):format(buf_year, buf_month, buf_day)
      local end_date = ("%04d-%02d-%02d"):format(buf_year, buf_month, buf_day + 1)
      local start_date_time = ("%04d-%02d-%02dT%s%s"):format(buf_year, buf_month, buf_day, start_time, timezone)
      local end_date_time = ("%04d-%02d-%02dT%s%s"):format(buf_year, buf_month, buf_day, end_time, timezone)

      if not start_time or not end_time then
        calendar_summary = start_time -- line hast less fields
        table.insert(diffs, {
          type = "new",
          summary = summary,
          calendar_summary = calendar_summary,
          start = {
            date = start_date,
          },
          ["end"] = {
            date = end_date,
          },
        })
      else
        table.insert(diffs, {
          type = "new",
          summary = summary,
          calendar_summary = calendar_summary,
          start = {
            dateTime = start_date_time,
          },
          ["end"] = {
            dateTime = end_date_time,
          },
        })
      end
    end
  end

  for _, event in pairs(day_events_by_id) do
    table.insert(diffs, {
      type = "delete",
      cached_event = event,
    })
  end

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
    for _, diff in ipairs(diffs) do
      if diff.type == "new" then
        assert(diff.calendar_summary, ("Diff has no calendar_summary %s"):format(vim.inspect(diff)))
        local calendar = iter(calendar_list.items):find(
          function(calendar) return calendar.summary == diff.calendar_summary end
        )

        M.create_event(token_info, calendar.id, diff, function(new_event)
          local cache_key = ("%s_%s"):format(year, month)
          local month_events = _cache_events[cache_key]
          table.insert(month_events, new_event)

          reload_if_last_diff()
        end)
      elseif diff.type == "edit" then
        local calendar = iter(calendar_list.items):find(
          ---@param calendar CalendarListEntry
          function(calendar) return calendar.id == diff.cached_event.organizer.email end
        )

        M.edit_event(token_info, calendar.id, diff, function(edited_event)
          local cached_event = diff.cached_event --[[@as table<unknown, unknown>]]

          -- can't only update some fields because google checks
          -- things like the last update time to check if the
          -- event has gone out-of-sync
          for key, _ in pairs(cached_event) do
            cached_event[key] = edited_event[key]
          end

          reload_if_last_diff()
        end)
      elseif diff.type == "delete" then
        local calendar = iter(calendar_list.items):find(
          ---@param calendar CalendarListEntry
          function(calendar) return calendar.id == diff.cached_event.organizer.email end
        )

        M.delete_event(token_info, calendar.id, diff, function()
          local cache_key = ("%s_%s"):format(year, month)
          local month_events = _cache_events[cache_key]
          for j, event in ipairs(month_events) do
            if event.id == diff.cached_event.id then table.remove(month_events, j) end
          end

          reload_if_last_diff()
        end)
      end
    end
  end

  vim.bo[buf].modified = false
  vim.bo[buf].modifiable = true
end

---@param year integer
---@param month integer
---@param opts? {refresh: boolean}
function CalendarView:show(year, month, opts)
  if not vim.tbl_isempty(self.day_bufs) then self.day_bufs = {} end
  if not vim.tbl_isempty(self.cal_bufs) then self.cal_bufs = {} end
  if not vim.tbl_isempty(self.cal_wins) then self.cal_wins = {} end

  M.get_token_info(function(token_info)
    M.get_calendar_list(token_info, function(calendar_list)
      M.get_events(token_info, calendar_list, year, month, opts, function(events)
        local first_day_month = os.date("*t", os.time { year = year, month = month, day = 1 }) --[[@as osdate]]
        local last_day_month = os.date("*t", os.time { year = year, month = month + 1, day = 0 })--[[@as osdate]]

        ---@type table<string, Event[]>
        local events_by_date = iter(events):fold(
          {},
          ---@param acc table<string, Event[]>
          ---@param event Event
          function(acc, event)
            local start_date ---@type {y: integer, m: integer, d: integer}
            if event.start.date then
              start_date = parse_date(event.start.date, {})
            elseif event.start.dateTime then
              start_date = parse_date_time(event.start.dateTime)
            end
            local end_date ---@type {y: integer, m: integer, d: integer}
            if event["end"].date then
              end_date = parse_date(event["end"].date, { is_end = true })
            elseif event["end"].dateTime then
              end_date = parse_date_time(event["end"].dateTime)
            end
            -- this only works if the event started in a previous/next month
            -- and continues into the current month. If the event started and
            -- concluded in the previous/next month (and is being shown in the
            -- current month because of something like a timezone issue), this
            -- will incorrectly show the event as taking place in all the days
            -- of the current month
            local start_day = start_date.m == first_day_month.month and start_date.d or 1
            local end_day = end_date.m == first_day_month.month and end_date.d or last_day_month.day
            for i = start_day, end_day do
              local key = ("%s_%s_%s"):format(year, month, i)
              if not acc[key] then acc[key] = {} end
              table.insert(acc[key], event)
            end
            return acc
          end
        )

        local factor = 1
        -- TODO: use max_[] to make last row/col longer if needed in order to use the full screen
        local max_width = math.floor(vim.o.columns * factor)
        local max_height = math.floor(vim.o.lines * factor)

        local w_in_m = self:w_in_m(year, month)

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

              api.nvim_buf_set_name(buf, ("calendar://day_%04d_%02d_%02d"):format(date.year, date.month, date.day))
              self.cal_bufs[y][x] = buf
            end
          end
        end

        self.month_win = api.nvim_open_win(self.month_buf, false, {
          focusable = false,
          relative = "editor",
          col = col,
          row = row,
          width = y_m_width,
          height = y_m_height,
          style = "minimal",
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

            keymap.set("n", "<c-l>", function()
              api.nvim_win_close(win, true)
              self:show(year, month, { refresh = true })
            end, { buffer = buf })
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
              callback = function() self:write(token_info, calendar_list, events_by_date, year, month, win, buf) end,
            })
          end
        end

        local days_in_month = {} ---@type integer[]
        for i = 1, last_day_month.day do
          table.insert(days_in_month, i)
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
              pattern = { sep, ":" },
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
            local events_text = iter(day_events)
              :map(function(event)
                if not event.start.dateTime then return ("/%s %s"):format(event.id, event.summary) end
                local start_date_time = parse_date_time(event.start.dateTime)
                local end_date_time = parse_date_time(event["end"].dateTime)
                return ("/%s %s%s%02d:%02d:%02d%s%02d:%02d:%02d"):format(
                  event.id,
                  event.summary,
                  sep,
                  start_date_time.h,
                  start_date_time.min,
                  start_date_time.s,
                  sep,
                  end_date_time.h,
                  end_date_time.min,
                  end_date_time.s
                )
              end)
              :totable()
            iter(day_events):each(
              ---@param event Event
              function(event)
                local calendar = iter(calendar_list.items):find(
                  ---@param calendar CalendarListEntry
                  function(calendar) return calendar.id == event.organizer.email end
                )

                if not calendar or not event.summary then return end
                local fg = compute_hex_color_group(calendar.foregroundColor, "fg")
                local bg = compute_hex_color_group(calendar.backgroundColor, "bg")
                highlighters[event.id .. "fg"] = { pattern = "%f[%w]()" .. event.summary .. "()%f[%W]", group = fg }
                highlighters[event.id .. "bg"] = { pattern = "%f[%w]()" .. event.summary .. "()%f[%W]", group = bg }
              end
            )

            vim.list_extend(lines, events_text)
          end
          -- TODO: add support for event.colorId using `get_colors` (currently I don't have any events with custom colors, so it's no neccesary)
          hl_enable(cal_buf, { highlighters = highlighters })

          api.nvim_buf_set_lines(cal_buf, 0, -1, true, lines)
          vim.bo[cal_buf].modified = false
        end)
      end)
    end)
  end)
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

---@param token_info TokenInfo
---@param cb fun(events: Colors)
function M.get_colors(token_info, cb)
  if _cache_colors then
    cb(_cache_colors)
    return
  end

  local colors_received_pattern = "CalendarColorsReceived"
  api.nvim_create_autocmd("User", {
    pattern = colors_received_pattern,
    ---@param opts {data:{colors: Colors}}
    callback = function(opts) cb(opts.data.colors) end,
    once = true,
  })
  if is_getting_colors then return end
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
        refresh_access_token(
          token_info.refresh_token,
          function(refreshed_token_info) M.get_colors(refreshed_token_info, cb) end
        )
        return
      end
      ---@cast colors +Colors
      ---@cast colors -ApiErrorResponse

      _cache_colors = colors
      is_getting_colors = false
      api.nvim_exec_autocmds("User", { pattern = colors_received_pattern, data = { colors = _cache_colors } })
    end)
  )
end

---@class Diff
---@field type "new"|"edit"|"delete"
---@field summary string
---@field start Date?
---@field end Date?
---@field cached_event Event?
---@field calendar_summary string?

---@param token_info TokenInfo
---@param diff Diff
---@param cb fun(new_event: Event)
function M.create_event(token_info, calendar_id, diff, cb)
  local data = vim.json.encode { start = diff.start, ["end"] = diff["end"], summary = diff.summary }
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
        refresh_access_token(
          token_info.refresh_token,
          function(refreshed_token_info) M.create_event(refreshed_token_info, calendar_id, diff, cb) end
        )
        return
      end
      ---@cast new_event +Event
      ---@cast new_event -ApiErrorResponse

      cb(new_event)
    end)
  )
end

---@param token_info TokenInfo
---@param diff Diff
---@param cb fun(edited_event: Event)
function M.edit_event(token_info, calendar_id, diff, cb)
  local cached_event = vim.deepcopy(diff.cached_event) --[[@as Event]]
  if diff.summary then cached_event.summary = diff.summary end
  if diff.start then cached_event.start = diff.start end
  if diff["end"] then cached_event["end"] = diff["end"] end
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
        refresh_access_token(
          token_info.refresh_token,
          function(refreshed_token_info) M.edit_event(refreshed_token_info, calendar_id, diff, cb) end
        )
        return
      end
      ---@cast edited_event +Event
      ---@cast edited_event -ApiErrorResponse

      cb(edited_event)
    end)
  )
end

---@param token_info TokenInfo
---@param diff Diff
---@param cb fun()
function M.delete_event(token_info, calendar_id, diff, cb)
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
        cb()
        return
      end

      local ok, response = pcall(vim.json.decode, result.stdout) ---@type boolean, string|ApiErrorResponse
      assert(ok, response)
      ---@cast response -string

      if response.error then
        ---@cast response -Event
        assert(response.error.status == "UNAUTHENTICATED", response.error.message)
        refresh_access_token(
          token_info.refresh_token,
          function(refreshed_token_info) M.edit_event(refreshed_token_info, calendar_id, diff, cb) end
        )
        return
      end
    end)
  )
end

function M.add_coq_completion()
  COQsources = COQsources or {} ---@type coq_sources
  COQsources[new_uid(COQsources)] = {
    name = "CL",
    fn = function(args, cb)
      local buf_name = api.nvim_buf_get_name(0)
      if not buf_name:match "^calendar://" then return cb() end
      if args.line:match "^/[^ ]+ " then return cb() end
      -- TODO: check that line matches the (to be defined) format for where the
      -- calendar name should go
      M.get_token_info(function(token_info)
        M.get_calendar_list(
          token_info,
          ---@param calendar_list CalendarList
          function(calendar_list)
            local items = iter(calendar_list.items)
              :map(
                ---@param calendar CalendarListEntry
                function(calendar) return { label = calendar.summary, insertText = calendar.summary } end
              )
              :totable()
            cb { isIncomplete = false, items = items }
          end
        )
      end)
    end,
  }
end
-- uncomment to debug
-- COQsources = {}
M.add_coq_completion()

M.CalendarView = CalendarView

return M
