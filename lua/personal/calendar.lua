-- TODO: maybe change asserts to vim.notify errors (?)
-- TODO: maybe show notifications (maybe using mini.notify?) while loading/waiting for responses (?)
local uv = vim.uv
local api = vim.api
local keymap = vim.keymap
local iter = vim.iter
local compute_hex_color_group = require("mini.hipatterns").compute_hex_color_group
local fs_exists = require("personal.util.general").fs_exists

local M = {}

local api_key = vim.env.GOOGLE_CALENDAR_API_KEY ---@type string
local client_id = vim.env.GOOGLE_CALENDAR_CLIENT_ID ---@type string
local client_secret = vim.env.GOOGLE_CALENDAR_CLIENT_SECRET ---@type string

local data_path = ("%s/%s"):format(vim.fn.stdpath "data", "/calendar")
data_path = vim.fs.normalize(data_path)

fs_exists(
  data_path,
  vim.schedule_wrap(function(exists, err)
    if exists == nil and err then
      vim.notify(err, vim.log.levels.ERROR)
      return
    end
    if not exists then vim.fn.mkdir(data_path) end
  end)
)

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
    <h1>Everything done, you can return to Neovim :D</h1>
    <h2>Your code is:</h2>
    <pre>%s</pre>
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
local _cache_token_info ---@type TokenInfo
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
      local ok, new_token_info = pcall(vim.json.decode, result.stdout) ---@type boolean, NewTokenInfo|ApiErrorResponse
      assert(ok, new_token_info)

      -- TODO: check for errors and refresh refresh_token if needed
      if new_token_info.error then error(new_token_info.error.message) end
      ---@cast new_token_info -ApiErrorResponse

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
local function get_token_info(cb)
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
  get_token_info(function(token_info)
    M.get_calendar_list(token_info, function(calendar_list)
      local buf = api.nvim_create_buf(false, false)
      api.nvim_buf_set_name(buf, "calendar://list")
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
          vim
            .iter(lines)
            :map(function(line)
              local summary, description, id = unpack(vim.split(line, sep, { trimempty = true }))
              return {
                summary = summary,
                description = description,
                id = id,
              }
            end)
            :each(function(calendar_info)
              -- TODO: handle CREATE, UPDATE and DELETE
              if not calendar_info.id then print(("Creating calendar with name %s"):format(calendar_info.summary)) end
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
  -- TODO: automatically or manually invalidate/reload this?
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
  get_token_info(function(token_info)
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
---@field date string
---@field dateTime string
---@field timeZone string

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

local _cache_events = {} ---@type table<string, Event[]> id_month_year -> events

---@param token_info TokenInfo
---@param calendar_list CalendarList
---@param year integer
---@param month integer
---@param cb fun(events: Event[])
function M.get_events(token_info, calendar_list, year, month, cb)
  local start_year = year
  local start_month = month
  local end_year = year
  local end_month = month + 1
  if end_month > 12 then
    end_year = end_year + 1
    end_month = end_month - 12
  end

  local time_min = ("%04d-%02d-01T00:00:00Z"):format(start_year, start_month)
  local time_max = ("%04d-%02d-01T00:00:00Z"):format(end_year, end_month)

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

          -- TODO: generalize error handling?
          if events.error then
            ---@cast events -CalendarEvents
            assert(events.error.status == "UNAUTHENTICATED", events.error.message)
            refresh_access_token(
              token_info.refresh_token,
              function(refreshed_token_info) M.get_events(refreshed_token_info, calendar_list, year, month, cb) end
            )
            return
          end
          ---@cast events +CalendarEvents
          ---@cast events -ApiErrorResponse

          table.insert(all_calendar_events, events)

          if #all_calendar_events == #calendar_list.items then
            _cache_events[key] = vim
              .iter(all_calendar_events)
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
---@return {y: integer, m: integer, d: integer}
local function parse_date(date)
  ---@type string, string, string, string, string, string, string, string
  local y, m, d = date:match "(%d%d%d%d)-(%d%d)-(%d%d)"
  return {
    y = tonumber(y),
    m = tonumber(m),
    d = tonumber(d),
  }
end

local days = { "Domingo", "Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado" }

function M.events_show()
  get_token_info(function(token_info)
    M.get_calendar_list(token_info, function(calendar_list)
      M.get_events(token_info, calendar_list, 2024, 10, function(events)
        -- TODO: today will have to be replaced with the first day of the month in order to show different months
        local today = os.date "*t" --[[@as osdate]]
        local last_day_month = os.date("*t", os.time { year = today.year, month = today.month + 1, day = 0 })

        ---@type table<string, Event[]>
        local events_by_date = iter(events):fold(
          {},
          ---@param acc table<string, Event[]>
          ---@param event Event
          function(acc, event)
            local start_date ---@type {y: integer, m: integer, d: integer}
            if event.start.date then
              start_date = parse_date(event.start.date)
            elseif event.start.dateTime then
              start_date = parse_date_time(event.start.dateTime)
            end
            local end_date ---@type {y: integer, m: integer, d: integer}
            if event["end"].date then
              end_date = parse_date(event["end"].date)
            elseif event["end"].dateTime then
              end_date = parse_date_time(event["end"].dateTime)
            end
            local year = today.year
            local month = today.month
            local start_day = start_date.m == today.month and start_date.d or 1
            local end_day = end_date.m == today.month and end_date.d or last_day_month.day
            for i = start_day, end_day do
              local key = ("%s_%s_%s"):format(year, month, i)
              if not acc[key] then acc[key] = {} end
              table.insert(acc[key], event)
            end
            return acc
          end
        )

        local days_in_month = {} ---@type integer[]
        for i = 1, last_day_month.day do
          table.insert(days_in_month, i)
        end

        M.calendar_view_show()
        local x ---@type integer calendar coordinates
        local y = 2 ---@type integer calendar coordinates
        iter(days_in_month):each(
          ---@param i integer
          function(i)
            local date = os.date("%Y-%m-%d", os.time { year = today.year, month = today.month, day = i }) --[[@as string]]
            local lines = { date }

            local key = ("%s_%s_%s"):format(today.year, today.month, i)
            local day_events = events_by_date[key]
            if day_events then
              local events_text = iter(day_events)
                :map(function(event)
                  if not event.start.dateTime then return ("%s%s%s"):format(event.summary, sep, event.id) end
                  local start_date_time = parse_date_time(event.start.dateTime)
                  local end_date_time = parse_date_time(event["end"].dateTime)
                  return ("%s%s%02d:%02d:%02d%s%02d:%02d:%02d"):format(
                    event.summary,
                    sep,
                    start_date_time.h,
                    start_date_time.m,
                    start_date_time.s,
                    sep,
                    end_date_time.h,
                    end_date_time.m,
                    end_date_time.s,
                    sep,
                    event.id
                  )
                end)
                :totable()
              vim.list_extend(lines, events_text)
            end

            local day = os.date("*t", os.time { year = today.year, month = today.month, day = i }) --[[@as osdate]]
            x = day.wday - 1
            if x <= 0 then x = x + 7 end
            local cal_buf = M.cal_bufs[y][x]
            if x == 7 then y = y + 1 end -- advance to next row for next iteration
            api.nvim_buf_set_lines(cal_buf, 0, -1, true, lines)
            vim.bo[cal_buf].modified = false
          end
        )
      end)
    end)
  end)
end

local cal_cols = 7
local cal_rows = 6
M.cal_bufs = {} ---@type table<integer, table<integer, integer>> cal_bufs[y][x] = buf 1-based
M.cal_wins = {} ---@type table<integer, table<integer, integer>> cal_wins[y][x] = win 1-based

function M.calendar_view_show()
  if not vim.tbl_isempty(M.cal_bufs) then M.cal_bufs = {} end
  if not vim.tbl_isempty(M.cal_wins) then M.cal_wins = {} end

  for y = 1, cal_rows do
    for x = 1, cal_cols do
      local buf = api.nvim_create_buf(false, false)

      if x == 1 then M.cal_bufs[y] = {} end

      local w_day = x + 1
      if w_day >= 8 then w_day = w_day - 7 end
      if y == 1 then
        api.nvim_buf_set_lines(buf, 0, -1, true, { days[w_day] })
        vim.bo[buf].modified = false
        vim.bo[buf].modifiable = false
      end

      M.cal_bufs[y][x] = buf
    end
  end

  local factor = 1
  local max_width = math.floor(vim.o.columns * factor)
  local max_height = math.floor(vim.o.lines * factor)

  local width = math.floor(max_width / cal_cols)
  local height = math.floor(max_height / cal_rows)

  local col = (vim.o.columns - max_width) / 2
  local row = (vim.o.lines - max_height) / 2

  for y = 1, cal_rows do
    local row_offset = (y - 1) * height
    for x = 1, cal_cols do
      local col_offset = (x - 1) * width
      local buf = M.cal_bufs[y][x]
      local win = api.nvim_open_win(buf, false, {
        relative = "editor",
        col = col + col_offset,
        row = row + row_offset,
        width = width,
        height = height,
        style = "minimal",
      })
      if y ~= 1 then
        vim.wo[win].winhighlight = "" -- since filchars eob is ' ', this will make non-focused windows a different color
      end
      if x == 1 then M.cal_wins[y] = {} end
      M.cal_wins[y][x] = win
    end
  end

  local all_bufs = iter(M.cal_bufs):flatten(1):totable()
  local all_wins = iter(M.cal_wins):flatten(1):totable()

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

  for y = 1, cal_rows do
    for x = 1, cal_cols do
      local buf = M.cal_bufs[y][x]
      local win = M.cal_wins[y][x]

      local win_l ---@type integer
      if x - 1 >= 1 then
        win_l = M.cal_wins[y][x - 1]
      else
        win_l = M.cal_wins[y][cal_cols]
      end
      keymap.set("n", "<left>", function() api.nvim_set_current_win(win_l) end, { buffer = buf })
      local win_r ---@type integer
      if x + 1 <= cal_cols then
        win_r = M.cal_wins[y][x + 1]
      else
        win_r = M.cal_wins[y][1]
      end
      keymap.set("n", "<right>", function() api.nvim_set_current_win(win_r) end, { buffer = buf })
      local win_u ---@type integer
      if y - 1 >= 1 then
        win_u = M.cal_wins[y - 1][x]
      else
        win_u = M.cal_wins[cal_rows][x]
      end
      keymap.set("n", "<up>", function() api.nvim_set_current_win(win_u) end, { buffer = buf })
      local win_d ---@type integer
      if y + 1 <= cal_rows then
        win_d = M.cal_wins[y + 1][x]
      else
        win_d = M.cal_wins[1][x]
      end
      keymap.set("n", "<down>", function() api.nvim_set_current_win(win_d) end, { buffer = buf })

      if y == 2 and x == 1 then api.nvim_set_current_win(win) end
    end
  end
end

M.events_show()
