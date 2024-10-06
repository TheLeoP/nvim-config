-- TODO: maybe change asserts to vim.notify errors (?)
local uv = vim.uv
local api = vim.api
local keymap = vim.keymap
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
---@return string
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
---@return string
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
---@param cb fun()
local function refresh_access_token(refresh_token, cb)
  local token_refreshed_pattern = "CalendarAccessTokenRefreshed"
  api.nvim_create_autocmd("User", {
    pattern = token_refreshed_pattern,
    callback = function() cb() end,
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
      local ok2, info = pcall(vim.json.encode, _cache_token_info) ---@type boolean, string
      assert(ok2, info)
      file:write(info)
      file:close()

      is_refreshing_access_token = false
      api.nvim_exec_autocmds("User", { pattern = token_refreshed_pattern })
    end)
  )
end

local scope = "https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/tasks"
scope = url_encode(scope)
local redirect_uri = "http://localhost:8080"
redirect_uri = url_encode(redirect_uri)

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

local ns = api.nvim_create_namespace "Calendar"

function M.calendars_show()
  get_token_info(function(token_info)
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
          refresh_access_token(token_info.refresh_token, function() M.calendars_show() end)
          return
        end
        ---@cast calendar_list +CalendarList
        ---@cast calendar_list -ApiErrorResponse

        -- UI
        local buf = api.nvim_create_buf(false, false)
        api.nvim_create_autocmd("BufLeave", {
          buffer = buf,
          callback = function() api.nvim_buf_delete(buf, { force = true }) end,
        })
        vim.iter(ipairs(calendar_list.items)):each(
          ---@param i integer
          ---@param calendar CalendarListEntry
          function(i, calendar)
            local row = i - 1
            -- TODO: move separators into variable?
            local line = ("%s | %s | %s"):format(
              calendar.summary,
              calendar.description or "[No description]",
              calendar.id
            )
            api.nvim_buf_set_lines(buf, row, row, true, { line })
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
          local id = line:match ".* | .* | (.*)"

          api.nvim_win_close(0, true)
          M.calendar_show(id)
        end, { buffer = buf })

        local width = math.floor(vim.o.columns * 0.7)
        local height = math.floor(vim.o.lines * 0.7)
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
    )
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

---@param id string
function M.calendar_show(id)
  get_token_info(function(token_info)
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

        -- TODO: generalize error handling?
        if calendar.error then
          ---@cast calendar -Calendar
          assert(calendar.error.status == "UNAUTHENTICATED", calendar.error.message)
          refresh_access_token(token_info.refresh_token, function() M.calendar_show(id) end)
          return
        end
        ---@cast calendar +Calendar
        ---@cast calendar -ApiErrorResponse

        local buf = api.nvim_create_buf(false, false)
        api.nvim_create_autocmd("BufLeave", {
          buffer = buf,
          callback = function() api.nvim_buf_delete(buf, { force = true }) end,
        })
        api.nvim_buf_set_lines(buf, 0, 0, true, vim.split(result.stdout, "\n"))
        api.nvim_buf_call(buf, function() vim.cmd.set "filetype=json" end)

        keymap.set("n", "-", function()
          api.nvim_win_close(0, true)
          M.calendars_show()
        end, { buffer = buf })

        local width = math.floor(vim.o.columns * 0.7)
        local height = math.floor(vim.o.lines * 0.7)
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
    )
  end)
end

M.calendars_show()
