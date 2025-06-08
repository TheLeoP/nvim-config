local uv = vim.uv
local api = vim.api
local fs_exists = require("personal.util.general").fs_exists
local uri_encode = require("vim.uri").uri_encode
local auv = require "personal.auv"
local co_resume = auv.co_resume

local M = {}

local client_id = vim.env.GOOGLE_CLIENT_ID ---@type string
local client_secret = vim.env.GOOGLE_CLIENT_SECRET ---@type string

local data_path = ("%s/%s"):format(vim.fn.stdpath "data", "/google")
data_path = vim.fs.normalize(data_path)
coroutine.wrap(function()
  local exists, err = fs_exists(data_path)
  if exists == nil and err then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
  if not exists then
    auv.schedule()
    vim.fn.mkdir(data_path)
  end
end)()

---@param opts {on_ready: fun(), on_code: fun(code: string)}
local function start_server(opts)
  local server = assert(uv.new_tcp())
  local buffer = {} ---@type string[]

  server:bind("127.0.0.1", 8080)
  server:listen(180, function(err)
    assert(not err, err)
    local client = assert(uv.new_tcp())
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
          assert(client:write(([[HTTP/1.1 200 OK
Content-Type: text/html

<!DOCTYPE html>
<html>
  <body>
    <h1>Everything done, you can close this and return to Neovim :D</h1>
  </body>
</html>
]]):format(code)))
          assert(client:read_stop())
          client:close()
          server:close()

          opts.on_code(code)
        end
      end
    )))
  end)
  opts.on_ready()
end

local token_url = "https://oauth2.googleapis.com/token"
local _cache_token_info = {} ---@type table<string, TokenInfo|nil>
local is_refreshing_access_token = false

local eager_refresh_threshold_seconds = 5 * 60

---Uses `token_info.refresh_token` to update token_info. If `refresh_token` has
---expired (taking `eager_refresh_threshold_seconds` into account), calls
---`get_token_info` to refresh it and also update token_info.
---@async
---@param token_info TokenInfo
---@param prefix string?
---@return TokenInfo
local function refresh_access_token(token_info, prefix)
  prefix = prefix or ""

  local refresh_token = token_info.refresh_token
  local token_path = ("%s/%stoken.json"):format(data_path, prefix)

  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  local token_refreshed_pattern = "GoogleAccessTokenRefreshed"
  if is_refreshing_access_token then
    auv.schedule()
    api.nvim_create_autocmd("User", {
      pattern = token_refreshed_pattern,
      ---@param opts {data:{token_info: TokenInfo}}
      callback = function(opts)
        co_resume(co, opts.data.token_info)
      end,
      once = true,
    })
    return coroutine.yield()
  end
  is_refreshing_access_token = true

  if _cache_token_info[prefix].refresh_token_expiry_date then
    local refresh_expiry_date = _cache_token_info[prefix].refresh_token_expiry_date --[[@as integer]]
    local now = os.time()
    local limit_date = os.date("*t", now) --[[@as osdate]]
    limit_date.sec = limit_date.sec + eager_refresh_threshold_seconds
    local limit = os.time(limit_date)

    if os.difftime(refresh_expiry_date, limit) <= 0 then
      _cache_token_info[prefix] = nil
      auv.schedule()
      if vim.fn.delete(token_path) ~= 0 then
        vim.notify(("Couldn't delete file %s"):format(token_path), vim.log.levels.WARN)
      end

      local new_token_info = assert(M.get_token_info(), "There is no token_info")
      auv.schedule()
      api.nvim_exec_autocmds("User", { pattern = token_refreshed_pattern, data = { token_info = new_token_info } })
      is_refreshing_access_token = false
      return new_token_info
    end
  end

  local params = ("client_id=%s&client_secret=%s&grant_type=refresh_token&refresh_token=%s"):format(
    client_id,
    client_secret,
    refresh_token
  )
  vim.system({
    "curl",
    "--data",
    params,
    "--http1.1",
    "--silent",
    token_url,
  }, { text = true }, function(result)
    co_resume(co, result)
  end)
  local result = coroutine.yield() ---@type vim.SystemCompleted

  assert(result.stderr == "", result.stderr)
  local ok, new_token_info = pcall(vim.json.decode, result.stdout) ---@type boolean, NewTokenInfo|ApiTokenErrorResponse|string
  assert(ok, new_token_info)
  ---@cast new_token_info -string

  assert(not new_token_info.error, vim.inspect(new_token_info))
  ---@cast new_token_info -ApiTokenErrorResponse

  local cached_token_info = _cache_token_info[prefix]
  assert(cached_token_info, "`cached_token_info` is nil")
  cached_token_info.access_token = new_token_info.access_token
  cached_token_info.expires_in = new_token_info.expires_in
  cached_token_info.scope = new_token_info.scope
  cached_token_info.token_type = new_token_info.token_type
  local now = os.time()
  local expiry_date = os.date("*t", now) --[[@as osdate]]
  expiry_date.sec = expiry_date.sec + new_token_info.expires_in
  cached_token_info.expiry_date = os.time(expiry_date)

  local file = io.open(token_path, "w")
  assert(file)
  local ok2, token_info_string = pcall(vim.json.encode, cached_token_info) ---@type boolean, string
  assert(ok2, token_info_string)
  file:write(token_info_string)
  file:close()

  api.nvim_exec_autocmds("User", { pattern = token_refreshed_pattern, data = { token_info = cached_token_info } })
  is_refreshing_access_token = false
  return cached_token_info
end

local scopes = {
  "https://www.googleapis.com/auth/calendar",
  "https://www.googleapis.com/auth/tasks",
  "https://www.googleapis.com/auth/drive",
}
local scope = table.concat(scopes, " ")
scope = assert(uri_encode(scope))
local redirect_uri = "http://localhost:8080"
redirect_uri = assert(uri_encode(redirect_uri))

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
---@field expiry_date integer
---@field refresh_token_expires_in integer | nil
---@field refresh_token_expiry_date integer | nil
---@field refresh_token string
---@field scope string
---@field token_type string

---@class NewTokenInfo
---@field access_token string
---@field expires_in integer
---@field scope string
---@field token_type string

---Reads from file if exists and asks for a token if not. If token has expired
---(taking `eager_refresh_threshold_seconds` into account), refreshes it.
---Caches last token.
---@param prefix string?
---@async
---@return TokenInfo|nil
function M.get_token_info(prefix)
  prefix = prefix or ""
  local token_path = ("%s/%stoken.json"):format(data_path, prefix)

  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  if not _cache_token_info[prefix] then
    local exists, err = fs_exists(token_path)
    if exists == nil and err then
      vim.notify(err, vim.log.levels.ERROR)
    elseif exists then
      local fd
      err, fd = auv.fs_open(token_path, "r", tonumber(444, 8)--[[@as integer]])
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

      _cache_token_info[prefix] = token_info
    end
  end

  if _cache_token_info[prefix] then
    local expiry_date = _cache_token_info[prefix].expiry_date
    local now = os.time()
    local limit_date = os.date("*t", now) --[[@as osdate]]
    limit_date.sec = limit_date.sec + eager_refresh_threshold_seconds
    local limit = os.time(limit_date)

    if os.difftime(expiry_date, limit) > 0 then return _cache_token_info[prefix] end

    return refresh_access_token(_cache_token_info[prefix], prefix)
  end

  vim.notify "You need to give us access to your google account"
  start_server {
    on_ready = function()
      vim.ui.open(full_auth_url)
      vim.notify "A webpage asking for access to your google accoutn has been opened"
    end,
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
        token_url,
      }, { text = true }, function(result)
        co_resume(co, result)
      end)
    end,
  }

  local result = coroutine.yield() ---@type vim.SystemCompleted
  assert(result.stderr == "", result.stderr)

  local ok, token_info = pcall(vim.json.decode, result.stdout) ---@type boolean, string|TokenInfo
  assert(ok, token_info)
  ---@cast token_info -string

  local now = os.time()
  local expiry_date = os.date("*t", now) --[[@as osdate]]
  expiry_date.sec = expiry_date.sec + token_info.expires_in
  token_info.expiry_date = os.time(expiry_date)

  if token_info.refresh_token_expires_in then
    local refresh_expiry_date = os.date("*t", now) --[[@as osdate]]
    refresh_expiry_date.sec = refresh_expiry_date.sec + token_info.refresh_token_expires_in
    token_info.refresh_token_expiry_date = os.time(refresh_expiry_date)
  end

  local file = io.open(token_path, "w")
  assert(file)
  file:write(vim.json.encode(token_info))
  file:close()

  _cache_token_info[prefix] = token_info

  return token_info
end

return M
