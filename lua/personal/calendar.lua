-- based on https://github.com/itchyny/calendar.vim

local uv = vim.uv
local api = vim.api
local keymap = vim.keymap
local iter = vim.iter
local compute_hex_color_group = require("mini.hipatterns").compute_hex_color_group
local hl_enable = require("mini.hipatterns").enable
local notify = require "mini.notify"
local uri_encode = require("vim.uri").uri_encode
local auv = require "personal.auv"
local co_resume = auv.co_resume
local google = require "personal.google"
local get_token_info = google.get_token_info

local M = {}

-- TODO: %z doesn't work in Windows, I think
---@type string, string, string
local timezone_sign, timezone_offset_hours_s, timezone_offset_minutes_s =
  tostring(os.date "%z"):match "([-+])(%d%d)(%d%d)"
local timezone = ("%s%s:%s"):format(timezone_sign, timezone_offset_hours_s, timezone_offset_minutes_s)
local timezone_offset_hours = (timezone_sign == "-" and -1 or 1) * tonumber(timezone_offset_hours_s)
local timezone_offset_minutes = (timezone_sign == "-" and -1 or 1) * tonumber(timezone_offset_minutes_s)
-- TODO: hardcoded timezone
local text_timezone = "America/Guayaquil"

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
---@param opts? {refresh:true}
---@return CalendarList, TokenInfo|nil
function M.get_calendar_list(opts)
  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  if opts and opts.refresh then _cache_calendar_list = nil end

  if _cache_calendar_list then return _cache_calendar_list end

  local token_info = get_token_info()
  assert(token_info, "`token_info` is nil")

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

      assert(not calendar_list.error, vim.inspect(calendar_list.error))
      ---@cast calendar_list -ApiErrorResponse

      _cache_calendar_list = calendar_list
      co_resume(co, calendar_list, nil)
    end)
  )
  return coroutine.yield()
end

local sep = " | "
M.sep = sep
---@param opts? {refresh:boolean}
function M.calendar_list_show(opts)
  coroutine.wrap(function()
    local calendar_list = M.get_calendar_list(opts)

    local buf = api.nvim_create_buf(false, false)
    api.nvim_buf_set_name(buf, "calendar://calendar_list")
    api.nvim_create_autocmd("BufLeave", {
      buffer = buf,
      callback = function()
        api.nvim_buf_delete(buf, { force = true })
      end,
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
                  function(calendar)
                    return calendar.id == id
                  end
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

        iter(calendars_by_id):each(function(_id, calendar)
          table.insert(diffs, { type = "delete", cached_calendar = calendar })
        end)

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
                local new_calendar = M.create_calendar(diff)
                assert(_cache_calendar_list)
                table.insert(_cache_calendar_list.items, new_calendar)

                reload_if_last_diff()
              end)()
            elseif diff.type == "edit" then
              coroutine.wrap(function()
                local edited_calendar = M.edit_calendar(diff)
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
                M.delete_calendar(diff)
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
    M.undo_clear(buf)
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
---@param id string
---@return Calendar
function M.get_calendar(id)
  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  if _cache_calendar[id] then return _cache_calendar[id] end

  local token_info = get_token_info()
  assert(token_info, "`token_info` is nil")

  vim.system(
    {
      "curl",
      "--http1.1",
      "--silent",
      "--header",
      ("Authorization: Bearer %s"):format(token_info.access_token),
      ("https://www.googleapis.com/calendar/v3/calendars/%s"):format(uri_encode(id)),
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)
      local ok, calendar = pcall(vim.json.decode, result.stdout) ---@type boolean, string|Calendar|ApiErrorResponse
      assert(ok, calendar)
      ---@cast calendar -string

      assert(not calendar.error, vim.inspect(calendar.error))
      ---@cast calendar -ApiErrorResponse

      _cache_calendar[id] = calendar
      co_resume(co, calendar)
    end)
  )
  return coroutine.yield()
end

---@async
---@param diff CalendarDiff
---@return Calendar
function M.create_calendar(diff)
  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  local token_info = get_token_info()
  assert(token_info, "`token_info` is nil")

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

      assert(not new_calendar.error, vim.inspect(new_calendar.error))
      ---@cast new_calendar -ApiErrorResponse

      co_resume(co, new_calendar)
    end)
  )
  return coroutine.yield()
end

---@async
---@param diff CalendarDiff
---@return Calendar
function M.edit_calendar(diff)
  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  local token_info = get_token_info()
  assert(token_info, "`token_info` is nil")

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

      assert(not edited_calendar.error, vim.inspect(edited_calendar.error))
      ---@cast edited_calendar -ApiErrorResponse

      co_resume(co, edited_calendar)
    end)
  )
  return coroutine.yield()
end

---@async
---@param diff CalendarDiff
function M.delete_calendar(diff)
  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  local token_info = get_token_info()
  assert(token_info, "`token_info` is nil")

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
        co_resume(co)
        return
      end

      local ok, response = pcall(vim.json.decode, result.stdout) ---@type boolean, string|ApiErrorResponse
      assert(ok, response)
      ---@cast response -string

      assert(not response.error, vim.inspect(response.error))
    end)
  )
  coroutine.yield()
end

---@param id string
function M.calendar_show(id)
  coroutine.wrap(function()
    local calendar = M.get_calendar(id)
    local buf = api.nvim_create_buf(false, false)

    api.nvim_create_autocmd("BufLeave", {
      buffer = buf,
      callback = function()
        api.nvim_buf_delete(buf, { force = true })
      end,
      once = true,
    })
    local calendar_string = vim.json.encode(calendar)
    api.nvim_buf_set_lines(buf, 0, 0, true, vim.split(calendar_string, "\n"))
    M.undo_clear(buf)
    vim.bo[buf].filetype = "json"
    vim.bo[buf].buftype = "acwrite"
    vim.bo[buf].swapfile = false

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
---@field colorId string?
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
---@field _calendar_id string Added to make it easier to get event information after grouping events from all calendars

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
---@param calendar_list CalendarList
---@param opts {start: CalendarDate, end: CalendarDate, refresh: boolean?, should_query_single_events: boolean?} start and end are exclusive
---@return table<string, Event[]>, TokenInfo|nil
function M.get_events(calendar_list, opts)
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

  local token_info = get_token_info()
  assert(token_info, "`token_info` is nil")

  -- in order to avoid duplicates on border days, if the whole date range hasn't been queried before, clean border days
  do
    local start_date = opts.start
    local end_date = opts["end"]
    local start_yday = os.date("*t", os.time(start_date --[[@as osdateparam]])).yday
    local end_yday = os.date("*t", os.time(end_date--[[@as osdateparam]])).yday
    if end_yday < start_yday then end_yday = end_yday + 365 end
    for i = 0, end_yday - start_yday - 1 do
      local date = os.date(
        "*t",
        os.time {
          year = start_date.year,
          month = start_date.month,
          day = start_date.day + i,
        }
      )
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
            uri_encode(calendar.id),
            uri_encode(time_min),
            uri_encode(time_max),
            opts.should_query_single_events
          ),
        },
        { text = true },
        vim.schedule_wrap(function(result)
          assert(result.stderr == "", result.stderr)
          local ok, events = pcall(vim.json.decode, result.stdout) ---@type boolean, string|CalendarEvents|ApiErrorResponse
          assert(ok, events)
          ---@cast events -string

          assert(not events.error, vim.inspect(events.error))
          ---@cast events -ApiErrorResponse

          iter(events.items):each(
            ---@param event Event
            function(event)
              event._calendar_id = calendar.id

              local start_date = M.parse_date_or_datetime(event.start, {})
              local end_date = M.parse_date_or_datetime(event["end"], { is_end = true })

              local start_yday = os.date(
                "*t",
                os.time {
                  year = start_date.y,
                  month = start_date.m,
                  day = start_date.d,
                }
              ).yday
              local end_yday = os.date(
                "*t",
                os.time {
                  year = end_date.y,
                  month = end_date.m,
                  day = end_date.d,
                }
              ).yday
              for i = 0, end_yday - start_yday do
                local date = os.date(
                  "*t",
                  os.time {
                    year = start_date.y,
                    month = start_date.m,
                    day = start_date.d + i,
                  }
                )
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
            co_resume(co, _cache_events, nil)
          end
        end)
      )
    end
  )
  return coroutine.yield()
end

---@param date_time string
---@return {y: integer, m: integer, d: integer, h: integer, min: integer, s: integer}
local function parse_date_time(date_time)
  if date_time:match "Z$" then
    local y, m, d, h, min, s = date_time:match "(%d%d%d%d)-(%d%d)-(%d%d)T(%d%d):(%d%d):(%d%d)Z"
    -- here, timestamp offset is 0 because of Z
    local local_offset = (timezone_offset_hours * 60 * 60) + (timezone_offset_minutes * 60)
    local day_time = os.date("*t", os.time {
      year = y,
      month = m,
      day = d,
      hour = h,
      min = min,
      sec = s,
    } + local_offset)
    return {
      y = day_time.year,
      m = day_time.month,
      d = day_time.day,
      h = day_time.hour,
      min = day_time.min,
      s = day_time.sec,
    }
  end

  ---@type string, string, string, string, string, string, string, string, string, string
  local y, m, d, h, min, s, offset_sign, offset_hours_s, offset_minutes_s =
    date_time:match "(%d%d%d%d)-(%d%d)-(%d%d)T(%d%d):(%d%d):(%d%d)([-+])(%d%d):(%d%d)"
  local offset_hours = (offset_sign == "-" and -1 or 1) * tonumber(offset_hours_s)
  offset_hours = offset_hours - timezone_offset_hours
  local offset_minutes = (offset_sign == "-" and -1 or 1) * tonumber(offset_minutes_s)
  offset_minutes = offset_minutes - timezone_offset_minutes
  local local_offset = (offset_hours * 60 * 60) + (offset_minutes * 60)
  local day_time = os.date("*t", os.time {
    year = y,
    month = m,
    day = d,
    hour = h,
    min = min,
    sec = s,
  } + local_offset)
  return {
    y = day_time.year,
    m = day_time.month,
    d = day_time.day,
    h = day_time.hour,
    min = day_time.min,
    s = day_time.sec,
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
---@field d_in_w_border_win integer
---@field y_m_border_win integer
---@field month_buf integer
---@field d_in_w_border_buf integer
---@field month_win integer
---@field day_bufs table<integer, integer> day_bufs[x] = buf 1-based
---@field day_wins table<integer, integer> day_wins[x] = win 1-based
---@field cal_bufs table<integer, table<integer, integer>> cal_bufs[y][x] = buf 1-based
---@field cal_wins table<integer, table<integer, integer>> cal_wins[y][x] = win 1-based
---@field current_win {[1]: integer, [2]: integer} [y][x] coordinates of current window
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
  self.day_bufs = {}
  self.day_wins = {}
  self.cal_bufs = {}
  self.cal_wins = {}
  return setmetatable(self, CalendarView)
end

---@param y integer
---@param x integer
function CalendarView:set_current_win(y, x)
  local win = self.cal_wins[y][x]
  api.nvim_set_current_win(win)
  self.current_win = { y, x }
end

function CalendarView:w_in_m(year, month)
  local first_day = os.date(
    "*t",
    os.time {
      year = year,
      month = month,
      day = 1,
    }
  )
  local last_day = os.date(
    "*t",
    os.time {
      year = year,
      month = month + 1,
      day = 0,
    }
  )

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
  local a = iter(digits)
    :map(function(digit)
      return vim.split(self.digits[digit], "\n")
    end)
    :fold(
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

---@param calendar_list CalendarList
---@param events_by_date table<string, Event>
---@param year integer
---@param month integer
---@param win integer
---@param buf integer
function CalendarView:write(calendar_list, events_by_date, year, month, win, buf)
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
            if calendar_summary:match "%d%d:%d%d:%d%d" or recurrence_fields:match "%d%d:%d%d:%d%d" then
              should_abort = true
              vim.notify(("The event `%s` has no calendar."):format(summary), vim.log.levels.ERROR)
              return
            end

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
            function(event)
              return event.id == id
            end
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
          if not calendar_summary then
            should_abort = true
            vim.notify(("The event `%s` has no calendar."):format(summary), vim.log.levels.ERROR)
            return
          end
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
          local calendar = iter(calendar_list.items):find(function(calendar)
            return calendar.summary == diff.calendar_summary
          end)

          coroutine.wrap(function()
            local new_event = M.create_event(calendar.id, diff)
            table.insert(day_events, new_event)

            reload_if_last_diff()
          end)()
        elseif diff.type == "edit" then
          local calendar_id = diff.cached_event.organizer.email

          coroutine.wrap(function()
            local edited_event = M.edit_event(calendar_id, diff)
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
          local calendar_id = diff.cached_event.organizer.email

          coroutine.wrap(function()
            M.delete_event(calendar_id, diff)
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
    local timer = assert(uv.new_timer())
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
  if self.year_buf then self.year_buf = nil end
  if self.year_win then self.year_win = nil end
  if self.d_in_w_border_win then self.d_in_w_border_win = nil end
  if self.y_m_border_win then self.y_m_border_win = nil end
  if self.month_buf then self.month_buf = nil end
  if self.d_in_w_border_buf then self.d_in_w_border_buf = nil end
  if self.y_m_border_buf then self.y_m_border_buf = nil end
  if self.month_win then self.month_win = nil end

  local first_day_month = os.date(
    "*t",
    os.time {
      year = year,
      month = month,
      day = 1,
    }
  ) --[[@as osdate]]

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
        vim.bo[buf].buftype = "acwrite"
        vim.bo[buf].swapfile = false

        if x == 1 then self.cal_bufs[y] = {} end

        local date = os.date(
          "*t",
          os.time {
            year = year,
            month = month,
            day = i - x_first_day_month,
          }
        ) --[[@as osdate]]
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
  local last_date_plus_one = os.date(
    "*t",
    os.time {
      year = last_date.year,
      month = last_date.month,
      day = last_date.day + 1,
    }
  )

  coroutine.wrap(function()
    local calendar_list = M.get_calendar_list {}

    -- NOTE: populate cache before creating buffers to avoid BufReadCmd from
    -- failing (because of async coroutine shenanigans, I think)
    M.get_colors()

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
    local events_by_date = M.get_events(calendar_list, {
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

    local d_in_w_total_width = width * self.d_in_w
    local d_in_w_border_width = max_width - d_in_w_total_width
    if d_in_w_border_width > 0 then
      self.d_in_w_border_buf = api.nvim_create_buf(false, false)
      vim.bo[self.d_in_w_border_buf].modified = false
      vim.bo[self.d_in_w_border_buf].modifiable = false
      vim.bo[self.d_in_w_border_buf].buftype = "nofile"
      vim.bo[self.d_in_w_border_buf].swapfile = false
    end

    local y_m_total_width = y_m_width * 2
    local y_m_border_width = max_width - y_m_total_width
    if y_m_border_width > 0 then
      self.y_m_border_buf = api.nvim_create_buf(false, false)
      vim.bo[self.y_m_border_buf].modified = false
      vim.bo[self.y_m_border_buf].modifiable = false
      vim.bo[self.y_m_border_buf].buftype = "nofile"
      vim.bo[self.y_m_border_buf].swapfile = false
    end

    self.month_buf = api.nvim_create_buf(false, false)

    api.nvim_buf_set_lines(self.month_buf, 0, -1, true, self:month(month, y_m_height))
    M.undo_clear(self.month_buf)
    vim.bo[self.month_buf].modified = false
    vim.bo[self.month_buf].modifiable = false
    vim.bo[self.month_buf].buftype = "nofile"
    vim.bo[self.month_buf].swapfile = false

    self.year_buf = api.nvim_create_buf(false, false)
    api.nvim_buf_set_lines(self.year_buf, 0, -1, true, self:year(year, y_m_height))
    M.undo_clear(self.year_buf)
    vim.bo[self.year_buf].modified = false
    vim.bo[self.year_buf].modifiable = false
    vim.bo[self.year_buf].buftype = "nofile"
    vim.bo[self.year_buf].swapfile = false

    for x = 1, self.d_in_w do
      local buf = api.nvim_create_buf(false, false)

      local w_day = x + 1

      if w_day >= 8 then w_day = w_day - 7 end
      local day_name = self.days[w_day]
      api.nvim_buf_set_lines(buf, 0, -1, true, { day_name })
      M.undo_clear(buf)
      hl_enable(buf, { highlighters = { day = { pattern = day_name, group = "TODO" } } })
      vim.bo[buf].modified = false
      vim.bo[buf].modifiable = false
      vim.bo[buf].buftype = "nofile"
      vim.bo[buf].swapfile = false

      self.day_bufs[x] = buf
    end

    local zindex = 1 -- small value to allow floating windows to be showed above
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
    vim.wo[self.month_win].wrap = false
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
    vim.wo[self.year_win].wrap = false

    if self.d_in_w_border_buf then
      local d_in_w_border_height = height * w_in_m + days_height

      self.d_in_w_border_win = api.nvim_open_win(self.d_in_w_border_buf, false, {
        focusable = false,
        relative = "editor",
        col = col + self.d_in_w * width,
        row = row + days_row_offset,
        width = d_in_w_border_width,
        height = d_in_w_border_height,
        style = "minimal",
        zindex = zindex,
      })
      vim.wo[self.d_in_w_border_win].winblend = 0
      vim.wo[self.d_in_w_border_win].wrap = false
    end
    if self.y_m_border_buf then
      local y_m_border_height = y_m_height

      self.y_m_border_win = api.nvim_open_win(self.y_m_border_buf, false, {
        focusable = false,
        relative = "editor",
        col = col + y_m_width * 2,
        row = row,
        width = y_m_border_width,
        height = y_m_border_height,
        style = "minimal",
        zindex = zindex,
      })
      vim.wo[self.y_m_border_win].winblend = 0
      vim.wo[self.y_m_border_win].wrap = false
    end

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
      vim.wo[win].wrap = false
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
        vim.wo[win].wrap = false
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
    if self.d_in_w_border_win then table.insert(all_wins, self.d_in_w_border_win) end
    if self.y_m_border_win then table.insert(all_wins, self.y_m_border_win) end

    api.nvim_create_autocmd("WinClosed", {
      pattern = iter(all_wins)
        :map(function(win)
          return tostring(win)
        end)
        :totable(),
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

    local today = os.date "*t"
    for y = 1, w_in_m do
      for x = 1, self.d_in_w do
        local buf = self.cal_bufs[y][x]
        local win = self.cal_wins[y][x]
        local buf_name = api.nvim_buf_get_name(buf)
        local buf_year, buf_month, buf_day = buf_name:match "^calendar://day_(%d%d%d%d)_(%d%d)_(%d%d)"
        buf_year, buf_month, buf_day = tonumber(buf_year), tonumber(buf_month), tonumber(buf_day)
        local key = ("%s_%s_%s"):format(buf_year, buf_month, buf_day)
        local day_events = events_by_date[key]

        keymap.set("n", "<F5>", function()
          api.nvim_win_close(win, true)
          self:show(year, month, { refresh = true })
        end, { buffer = buf })
        keymap.set("n", "<Del>", function()
          M.calendar_list_show()
        end, { buffer = buf })
        keymap.set("n", "<c-cr>", function()
          M.event_show(calendar_list, day_events, { recurring = true })
        end, { buffer = buf })
        keymap.set("n", "<cr>", function()
          M.event_show(calendar_list, day_events, {})
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
        local x_l ---@type integer
        if x - 1 >= 1 then
          x_l = x - 1
        else
          x_l = self.d_in_w
        end
        keymap.set("n", "<left>", function()
          self:set_current_win(y, x_l)
        end, { buffer = buf })
        local x_r ---@type integer
        if x + 1 <= self.d_in_w then
          x_r = x + 1
        else
          x_r = 1
        end

        keymap.set("n", "<right>", function()
          self:set_current_win(y, x_r)
        end, { buffer = buf })
        local y_u ---@type integer
        if y - 1 >= 1 then
          y_u = y - 1
        else
          y_u = w_in_m
        end
        keymap.set("n", "<up>", function()
          self:set_current_win(y_u, x)
        end, { buffer = buf })
        local y_d ---@type integer
        if y + 1 <= w_in_m then
          y_d = y + 1
        else
          y_d = 1
        end
        keymap.set("n", "<down>", function()
          self:set_current_win(y_d, x)
        end, { buffer = buf })

        -- TODO: use this for other kinds of buffers
        api.nvim_create_autocmd("BufReadCmd", {
          buffer = buf,
          callback = function()
            local day_num = ("%s"):format(buf_day)
            local lines = { day_num }

            if not day_events then
              api.nvim_buf_set_lines(buf, 0, -1, true, lines)
              return
            end

            -- TODO: sort only once
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
                  local _a = parse_date_time(a.start.dateTime)
                  local _b = parse_date_time(b.start.dateTime)
                  if _a.h ~= _b.h then
                    return _a.h < _b.h
                  elseif _a.h == _b.h and _a.min ~= _b.min then
                    return _a.min < _b.min
                  else
                    return _a.s < _b.s
                  end
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

            vim.list_extend(lines, events_text)
            api.nvim_buf_set_lines(buf, 0, -1, true, lines)
          end,
        })

        api.nvim_create_autocmd("BufWriteCmd", {
          buffer = buf,
          callback = function()
            coroutine.wrap(function()
              self:write(calendar_list, events_by_date, year, month, win, buf)
            end)()
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
            pattern = { sep, ":", ";", "=" },
            group = "Delimiter",
          },
        }

        iter(day_events):each(
          ---@param event Event
          function(event)
            local pattern = "^/[^ ]+ ()" .. vim.pesc(event.summary) .. "()"

            if event.attendees then
              ---@type Attendee|nil
              local attendee = iter(event.attendees):find(
                ---@param attendee Attendee
                function(attendee)
                  -- TODO: is this true for all events?
                  return attendee.email == event.organizer.email
                end
              )
              if attendee and attendee.responseStatus == "declined" then
                highlighters[event.id .. "deprecated"] = { pattern = pattern, group = "DiagnosticDeprecated" }
              end
            end

            ---@type CalendarListEntry|nil
            local calendar = iter(calendar_list.items):find(
              ---@param calendar CalendarListEntry
              function(calendar)
                return calendar.id == event._calendar_id
              end
            )

            if not calendar or not event.summary then return end

            local colors = M.get_colors()
            local current_color = event.colorId and colors.event[event.colorId] or nil ---@type Color?

            local calendar_fg = current_color and current_color.foreground or calendar.foregroundColor
            local calendar_bg = current_color and current_color.background or calendar.backgroundColor
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

        if today.day == buf_day and today.month == buf_month and today.year == buf_year then
          highlighters.day = {
            pattern = "^%d+",
            group = "",
            extmark_opts = function(buf, match, data)
              return {
                end_row = data.line,
                end_col = 0,
                hl_group = "DiffText",
                hl_eol = true,
              }
            end,
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
        vim.b[buf].minihipatterns_config = { highlighters = highlighters }

        api.nvim_create_autocmd("BufEnter", {
          buffer = buf,
          callback = function() -- NOTE:
            -- * after `vim.cmd.edit` because it resets `MiniHipatterns`.
            -- * after setting buf local config
            -- * before global config kicks in because the cache will use it instead of the buffer local config
            hl_enable(buf)
          end,
        })
        api.nvim_win_call(win, function()
          vim.cmd.edit()
        end)
      end
    end

    iter(self.cal_bufs):flatten(1):each(function(buf)
      local buf_name = api.nvim_buf_get_name(buf)
      local buf_year, buf_month, buf_day = buf_name:match "^calendar://day_(%d%d%d%d)_(%d%d)_(%d%d)"
      buf_year, buf_month, buf_day = tonumber(buf_year), tonumber(buf_month), tonumber(buf_day)

      if self.current_win and buf == self.cal_bufs[1][1] then
        local y, x = unpack(self.current_win) ---@type integer, integer
        if not self.cal_wins[y] or not self.cal_wins[y][x] then
          self:set_current_win(1, 1)
          return
        end
        self:set_current_win(y, x)
      elseif not self.current_win and today.day == buf_day and today.month == buf_month and today.year == buf_year then
        local x, y ---@type integer?, integer?
        for j, bufs in ipairs(self.cal_bufs) do
          for i, cal_buf in ipairs(bufs) do
            if cal_buf == buf then
              x, y = i, j
            end
          end
        end
        assert(y)
        assert(x)
        self:set_current_win(y, x)
      elseif not self.current_win and (today.month ~= month or today.year ~= year) and buf == self.cal_bufs[1][1] then
        self:set_current_win(1, 1)
      end
    end)

    api.nvim_create_autocmd("VimResized", {
      group = api.nvim_create_augroup("calendar-resized", {}),
      nested = true,
      callback = function()
        api.nvim_win_close(0, true)
        self:show(year, month, opts)
      end,
    })
  end)()
end

---@class Color
---@field background string
---@field foreground string

---@class Colors
---@field kind "calendar#colors"
---@field updated string
---@field calendar table<string, Color>
---@field event table<string, Color>

local _cache_colors ---@type Colors
local is_getting_colors = false

---@async
---@return Colors
function M.get_colors()
  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  if _cache_colors then return _cache_colors end

  local token_info = get_token_info()
  assert(token_info, "`token_info` is nil")

  local colors_received_pattern = "CalendarColorsReceived"
  api.nvim_create_autocmd("User", {
    pattern = colors_received_pattern,
    ---@param opts {data:{colors: Colors}}
    callback = function(opts)
      co_resume(co, opts.data.colors)
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

      assert(not colors.error, vim.inspect(colors.error))
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
---@param diff EventDiff
---@return Event
function M.create_event(calendar_id, diff)
  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  local token_info = get_token_info()
  assert(token_info, "`token_info` is nil")

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
      ("https://www.googleapis.com/calendar/v3/calendars/%s/events"):format(uri_encode(calendar_id)),
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)
      local ok, new_event = pcall(vim.json.decode, result.stdout) ---@type boolean, string|Event|ApiErrorResponse
      assert(ok, new_event)
      ---@cast new_event -string

      assert(not new_event.error, vim.inspect(new_event.error))
      ---@cast new_event -ApiErrorResponse

      co_resume(co, new_event)
    end)
  )
  return coroutine.yield()
end

---@async
---@param diff EventDiff
---@return Event
function M.edit_event(calendar_id, diff)
  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  local token_info = get_token_info()
  assert(token_info, "`token_info` is nil")

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
        uri_encode(calendar_id),
        uri_encode(diff.cached_event.id)
      ),
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)
      local ok, edited_event = pcall(vim.json.decode, result.stdout) ---@type boolean, string|Event|ApiErrorResponse
      assert(ok, edited_event)
      ---@cast edited_event -string

      assert(not edited_event.error, vim.inspect(edited_event.error))
      ---@cast edited_event -ApiErrorResponse

      co_resume(co, edited_event)
    end)
  )
  return coroutine.yield()
end

---@async
---@param calendar_id string
---@param diff EventDiff
function M.delete_event(calendar_id, diff)
  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  local token_info = get_token_info()
  assert(token_info, "`token_info` is nil")

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
        uri_encode(calendar_id),
        uri_encode(diff.cached_event.id)
      ),
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)

      if result.stdout == "" then
        co_resume(co)
        return
      end

      local ok, response = pcall(vim.json.decode, result.stdout) ---@type boolean, string|ApiErrorResponse
      assert(ok, response)
      ---@cast response -string

      assert(not response.error, vim.inspect(response.error))
    end)
  )
  coroutine.yield()
end

-- Maybe use this only for recurring events?
local _cache_event = {} ---@type table<string, Event> recurringEventId -> Event

---@async
---@param calendar_id string
---@param id string
---@param opts {refresh: boolean?}
---@return Event, TokenInfo|nil
function M.get_event(calendar_id, id, opts)
  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")
  if opts.refresh then _cache_event = {} end

  if _cache_event[id] then return _cache_event[id] end

  local token_info = get_token_info()
  assert(token_info, "`token_info` is nil")

  vim.system(
    {
      "curl",
      "--http1.1",
      "--silent",
      "--header",
      ("Authorization: Bearer %s"):format(token_info.access_token),
      ("https://www.googleapis.com/calendar/v3/calendars/%s/events/%s"):format(uri_encode(calendar_id), uri_encode(id)),
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)
      local ok, event = pcall(vim.json.decode, result.stdout) ---@type boolean, string|Event|ApiErrorResponse
      assert(ok, event)
      ---@cast event -string

      assert(not event.error, vim.inspect(event.error))
      ---@cast event -ApiErrorResponse

      _cache_event[id] = event
      co_resume(co, event, nil)
    end)
  )
  return coroutine.yield()
end

---@async
---@param buf integer
---@param win integer
---@param calendar_list CalendarList
---@param day_events Event[]
---@param opts {refresh: boolean?, recurring: boolean?}
local function event_write(buf, win, calendar_list, day_events, opts)
  local lines = api.nvim_buf_get_lines(buf, 0, -1, true)

  local id = api.nvim_buf_get_name(buf):match "^calendar://event_(.*)"
  local cached_event = _cache_event[id]
  local calendar_id = cached_event.organizer.email

  if #lines == 1 and lines[1] == "" then
    M.delete_event(calendar_id, { type = "delete", cached_event = cached_event })
    api.nvim_win_close(win, true)
    return
  end

  local summary = lines[1]:match "^summary: (.*)"

  local recurrence = vim.split(lines[2]:match "^recurrence: (.*)", " ") ---@type string[]|nil
  if recurrence and #recurrence == 1 and recurrence[1] == "" then recurrence = nil end
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

  local new_event = M.edit_event(calendar_id, {
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
  M.event_show(calendar_list, day_events, opts)
end

---@param calendar_list CalendarList
---@param day_events Event[]
---@param opts {refresh: boolean?, recurring: boolean?}
function M.event_show(calendar_list, day_events, opts)
  coroutine.wrap(function()
    local line = api.nvim_get_current_line()
    if not line:match "^/[^ ]+" then return end

    local event_id = line:match "^/([^ ]+)" ---@type string
    local events = day_events

    ---@type Event
    local event = iter(events):find(
      ---@param event Event
      function(event)
        return event.id == event_id
      end
    )
    assert(event, ("There is no event with id %s"):format(event_id))
    if not event.recurringEventId and opts.recurring then
      vim.notify(("Event %s has no recurringEventId"):format(event.summary))
      return
    end

    ---@type Calendar
    local calendar = iter(calendar_list.items):find(
      ---@param calendar CalendarListEntry
      function(calendar)
        return calendar.id == event._calendar_id
      end
    )
    assert(calendar, ("There is no calendar for event %s"):format(event_id))

    local consulted_id = opts.recurring and event.recurringEventId or event.id
    local recurring_event = M.get_event(calendar.id, consulted_id, opts)

    local is_recurrent = recurring_event.recurrence and not vim.tbl_isempty(recurring_event.recurrence)
    local recurrence = is_recurrent and table.concat(recurring_event.recurrence, " ") or ""
    local _start = recurring_event.start.date or recurring_event.start.dateTime
    local _end = recurring_event["end"].date or recurring_event["end"].dateTime
    local reminders = ("%s%s%s"):format(
      recurring_event.reminders.useDefault and "default" or "nodefault",
      sep,
      iter(recurring_event.reminders.overrides or {})
        :map(function(o)
          return ("%s min : %s"):format(o.minutes, o.method)
        end)
        :join(sep)
    )

    local buf = api.nvim_create_buf(false, false)
    api.nvim_buf_set_name(buf, ("calendar://event_%s"):format(consulted_id))
    api.nvim_create_autocmd("BufLeave", {
      buffer = buf,
      callback = function()
        api.nvim_buf_delete(buf, { force = true })
      end,
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
    M.undo_clear(buf)

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
        coroutine.wrap(function()
          event_write(buf, win, calendar_list, day_events, opts)
        end)()
      end,
    })
    keymap.set("n", "<F5>", function()
      api.nvim_win_close(win, true)
      M.event_show(calendar_list, day_events, { refresh = true, recurring = opts.recurring })
    end, { buffer = buf })
  end)()
end

---@param buf integer
function M.undo_clear(buf)
  local saved_undolevels = api.nvim_get_option_value("undolevels", { buf = buf })
  api.nvim_set_option_value("undolevels", -1, { buf = buf })
  api.nvim_buf_set_lines(buf, 0, 0, true, {}) -- make an empy change to remove old undos. See `:h clear-undo`
  api.nvim_set_option_value("undolevels", saved_undolevels, { buf = buf })
end

M.CalendarView = CalendarView

return M
