local uv = vim.uv
local api = vim.api
local fs_exists = require("personal.util.general").fs_exists
local url_encode = require("personal.util.general").url_encode
local auv = require "personal.auv"
local co_resume = auv.co_resume

local M = {}

local api_key = vim.env.GOOGLE_API_KEY ---@type string
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
local _cache_token_info = {} ---@type table<string, TokenInfo>
local is_refreshing_access_token = false

---@async
---@param refresh_token string
---@param prefix string?
---@return TokenInfo
function M.refresh_access_token(refresh_token, prefix)
  prefix = prefix or ""
  local token_path = ("%s/%stoken.json"):format(data_path, prefix)

  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  local token_refreshed_pattern = "GoogleAccessTokenRefreshed"
  api.nvim_create_autocmd("User", {
    pattern = token_refreshed_pattern,
    ---@param opts {data:{token_info: TokenInfo}}
    callback = function(opts) co_resume(co, opts.data.token_info) end,
    once = true,
  })
  if is_refreshing_access_token then return coroutine.yield() end
  is_refreshing_access_token = true

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
  }, { text = true }, function(result) co_resume(co, result) end)
  local result = coroutine.yield() ---@type vim.SystemCompleted

  assert(result.stderr == "", result.stderr)
  local ok, new_token_info = pcall(vim.json.decode, result.stdout) ---@type boolean, NewTokenInfo|ApiTokenErrorResponse|string
  assert(ok, new_token_info)
  ---@cast new_token_info -string

  local token_info ---@type TokenInfo
  if new_token_info.error then
    ---@cast new_token_info -NewTokenInfo
    assert(new_token_info.error == "invalid_grant", vim.inspect(new_token_info))

    _cache_token_info[prefix] = nil
    auv.schedule()
    if vim.fn.delete(token_path) == 0 then
      vim.notify(("Couldn't delete file %s"):format(token_path), vim.log.levels.WARN)
    end

    token_info = assert(M.get_token_info(), "There is no token_info")
  else
    ---@cast new_token_info +NewTokenInfo
    ---@cast new_token_info -ApiTokenErrorResponse

    local cached_token_info = _cache_token_info[prefix]
    cached_token_info.access_token = new_token_info.access_token
    cached_token_info.expires_in = new_token_info.expires_in
    cached_token_info.scope = new_token_info.scope
    cached_token_info.token_type = new_token_info.token_type

    local file = io.open(token_path, "w")
    assert(file)
    local ok2, token_info_string = pcall(vim.json.encode, cached_token_info) ---@type boolean, string
    assert(ok2, token_info_string)
    file:write(token_info_string)
    file:close()

    token_info = cached_token_info
  end

  -- to be executed after coroutine.yield()
  vim.schedule(function()
    api.nvim_exec_autocmds("User", { pattern = token_refreshed_pattern, data = { token_info = token_info } })
    is_refreshing_access_token = false
  end)

  return coroutine.yield()
end

local scope =
  "https://www.googleapis.com/auth/calendar https://www.googleapis.com/auth/tasks https://www.googleapis.com/auth/drive"
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
---@param prefix string?
---@async
---@return TokenInfo|nil
function M.get_token_info(prefix)
  prefix = prefix or ""
  local token_path = ("%s/%stoken.json"):format(data_path, prefix)

  local co = coroutine.running()
  assert(co, "The function must run inside a coroutine")

  if _cache_token_info[prefix] then return _cache_token_info[prefix] end

  local exists, err = fs_exists(token_path)
  if exists == nil and err then
    vim.notify(err, vim.log.levels.ERROR)
    return
  end
  if exists then
    local fd
    err, fd = auv.fs_open(token_path, "r", 292) ---444
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
    return token_info
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
        -- TODO: is this needed?
        -- "--insecure",
        token_url,
      }, { text = true }, function(result) co_resume(co, result) end)
    end,
  }

  local result = coroutine.yield() ---@type vim.SystemCompleted
  assert(result.stderr == "", result.stderr)

  local ok, token_info = pcall(vim.json.decode, result.stdout) ---@type boolean, string|TokenInfo
  assert(ok, token_info)
  ---@cast token_info -string

  local file = io.open(token_path, "w")
  assert(file)
  file:write(result.stdout)
  file:close()

  _cache_token_info[prefix] = token_info

  return token_info
end

return M
