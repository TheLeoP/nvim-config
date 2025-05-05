local api = vim.api
local uri_encode = require("vim.uri").uri_encode

local api_key = vim.env.JOIN_API_KEY ---@type string
local device_id = vim.env.JOIN_DEVICE_ID ---@type string
local sender_id = vim.env.JOIN_SENDER_ID ---@type string

local M = {}

---@class JoinResponse
---@field success boolean
---@field errorMessage string?
---@field userAuthError boolean

---@param text string
function M.clipboard(text)
  local url = ("https://joinjoaomgcd.appspot.com/_ah/api/messaging/v1/sendPush?apikey=%s&deviceId=%s&clipboard=%s"):format(
    uri_encode(api_key),
    uri_encode(device_id),
    uri_encode(text)
  )
  vim.system(
    {
      "curl",
      "--http1.1",
      "--silent",
      url,
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)
      local ok, response = pcall(vim.json.decode, result.stdout) ---@type boolean, JoinResponse
      assert(ok, response)

      assert(response.success, response.errorMessage or vim.inspect(response))
    end)
  )
end

---@param buf integer
function M.write_buffer(buf)
  local lines = api.nvim_buf_get_lines(buf, 0, -1, true)
  M.clipboard(table.concat(lines, "\n"))
end

---@param cellphone_number string
function M.call(cellphone_number)
  local url = ("https://joinjoaomgcd.appspot.com/_ah/api/messaging/v1/sendPush?apikey=%s&deviceId=%s&callnumber=%s"):format(
    uri_encode(api_key),
    uri_encode(device_id),
    uri_encode(cellphone_number)
  )
  vim.system(
    {
      "curl",
      "--http1.1",
      "--silent",
      url,
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)
      local ok, response = pcall(vim.json.decode, result.stdout) ---@type boolean, JoinResponse
      assert(ok, response)

      assert(response.success, response.errorMessage or vim.inspect(response))
    end)
  )
end

function M.find()
  local url = ("https://joinjoaomgcd.appspot.com/_ah/api/messaging/v1/sendPush?apikey=%s&deviceId=%s&find=true"):format(
    uri_encode(api_key),
    uri_encode(device_id)
  )
  vim.system(
    {
      "curl",
      "--http1.1",
      "--silent",
      url,
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)
      local ok, response = pcall(vim.json.decode, result.stdout) ---@type boolean, JoinResponse
      assert(ok, response)

      assert(response.success, response.errorMessage or vim.inspect(response))
    end)
  )
end

---@param text string
---@param language string
function M.say(text, language)
  local url = ("https://joinjoaomgcd.appspot.com/_ah/api/messaging/v1/sendPush?apikey=%s&deviceId=%s&say=%s&language=%s"):format(
    uri_encode(api_key),
    uri_encode(device_id),
    uri_encode(text),
    uri_encode(language)
  )
  vim.system(
    {
      "curl",
      "--http1.1",
      "--silent",
      url,
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)
      local ok, response = pcall(vim.json.decode, result.stdout) ---@type boolean, JoinResponse
      assert(ok, response)

      assert(response.success, response.errorMessage or vim.inspect(response))
    end)
  )
end

---@param name string
function M.open_app(name)
  local url = ("https://joinjoaomgcd.appspot.com/_ah/api/messaging/v1/sendPush?apikey=%s&deviceId=%s&app=%s"):format(
    uri_encode(api_key),
    uri_encode(device_id),
    uri_encode(name)
  )
  vim.system(
    {
      "curl",
      "--http1.1",
      "--silent",
      url,
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)
      local ok, response = pcall(vim.json.decode, result.stdout) ---@type boolean, JoinResponse
      assert(ok, response)

      assert(response.success, response.errorMessage or vim.inspect(response))
    end)
  )
end

---@class JoinNotifyOpts
---@field title string?
---@field icon string?
---@field smallicon string?
---@field priority -2|-1|0|1|2?
---@field vibration string?
---@field dismiss_on_touch boolean?
---@field image string?
---@field group string?
---@field sound string?
---@field actions string?
---@field url string?
---@field text string?

---@param opts JoinNotifyOpts
function M.notify(opts)
  local _additional_params = {} ---@type string[]
  if opts.text then table.insert(_additional_params, ("text=%s"):format(uri_encode(opts.text))) end
  if opts.title then table.insert(_additional_params, ("title=%s"):format(uri_encode(opts.title))) end
  if opts.icon then table.insert(_additional_params, ("icon=%s"):format(uri_encode(opts.icon))) end
  if opts.smallicon then table.insert(_additional_params, ("smallicon=%s"):format(uri_encode(opts.smallicon))) end
  if opts.priority then table.insert(_additional_params, ("priority=%s"):format(opts.priority)) end
  if opts.vibration then table.insert(_additional_params, ("vibration=%s"):format(uri_encode(opts.vibration))) end
  if opts.dismiss_on_touch then table.insert(_additional_params, "dismissOnTouch=true") end
  if opts.image then table.insert(_additional_params, ("image=%s"):format(uri_encode(opts.image))) end
  if opts.group then table.insert(_additional_params, ("group=%s"):format(uri_encode(opts.group))) end
  if opts.sound then table.insert(_additional_params, ("sound=%s"):format(uri_encode(opts.sound))) end
  if opts.actions then table.insert(_additional_params, ("actions=%s"):format(uri_encode(opts.actions))) end
  if opts.url then table.insert(_additional_params, ("url=%s"):format(uri_encode(opts.url))) end

  local additional_params = table.concat(_additional_params, "&")
  local url = ("https://joinjoaomgcd.appspot.com/_ah/api/messaging/v1/sendPush?apikey=%s&deviceId=%s&%s"):format(
    uri_encode(api_key),
    uri_encode(device_id),
    additional_params
  )
  vim.system(
    {
      "curl",
      "--http1.1",
      "--silent",
      url,
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)
      local ok, response = pcall(vim.json.decode, result.stdout) ---@type boolean, JoinResponse
      assert(ok, response)

      assert(response.success, response.errorMessage or vim.inspect(response))
    end)
  )
end

-- Invalid Push: Must include at least one of text, clipboard, url, file,
-- callnumber, smsnumber, smstext, wallpaper, interruptionFilter, mediaVolume,
-- ringVolume, alarmVolume, say, app, appPackage, intent, play, pause,
-- playpause, back, next, mediaSearch, actions, location or find

---@param action 'playpause'|'play'|'pause'|'back'|'next'|'back'
function M.media(action)
  local url = ("https://joinjoaomgcd.appspot.com/_ah/api/messaging/v1/sendPush?apikey=%s&deviceId=%s&%s=true"):format(
    uri_encode(api_key),
    uri_encode(device_id),
    action
  )
  vim.system(
    {
      "curl",
      "--http1.1",
      "--silent",
      url,
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)
      local ok, response = pcall(vim.json.decode, result.stdout) ---@type boolean, JoinResponse
      assert(ok, response)

      assert(response.success, response.errorMessage or vim.inspect(response))
    end)
  )
end

---@param text string
function M.media_search(text)
  local url = ("https://joinjoaomgcd.appspot.com/_ah/api/messaging/v1/sendPush?apikey=%s&deviceId=%s&mediaSearch=%s"):format(
    uri_encode(api_key),
    uri_encode(device_id),
    uri_encode(text)
  )
  vim.system(
    {
      "curl",
      "--http1.1",
      "--silent",
      url,
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)
      local ok, response = pcall(vim.json.decode, result.stdout) ---@type boolean, JoinResponse
      assert(ok, response)

      assert(response.success, response.errorMessage or vim.inspect(response))
    end)
  )
end

---Location is received in the device identified by `sender_id`
function M.location()
  local url = ("https://joinjoaomgcd.appspot.com/_ah/api/messaging/v1/sendPush?apikey=%s&deviceId=%s&location=true&senderId=%s"):format(
    uri_encode(api_key),
    uri_encode(device_id),
    uri_encode(sender_id)
  )
  vim.system(
    {
      "curl",
      "--http1.1",
      "--silent",
      url,
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)
      local ok, response = pcall(vim.json.decode, result.stdout) ---@type boolean, JoinResponse
      assert(ok, response)

      assert(response.success, response.errorMessage or vim.inspect(response))
    end)
  )
end

---@class JoinDevices
---@field id string
---@field regId string
---@field regId2 string
---@field userAccount string
---@field deviceId string
---@field deviceName string
---@field deviceType integer
---@field apiLevel integer

---@class JoinDevicesResponse: JoinResponse
---@field records JoinDevices[]

---@param cb fun(devices: JoinDevices[])
function M.get_devices(cb)
  local url = ("https://joinjoaomgcd.appspot.com/_ah/api/registration/v1/listDevices?apikey=%s"):format(
    uri_encode(api_key)
  )
  vim.system(
    {
      "curl",
      "--http1.1",
      "--silent",
      url,
    },
    { text = true },
    vim.schedule_wrap(function(result)
      assert(result.stderr == "", result.stderr)
      local ok, response = pcall(vim.json.decode, result.stdout) ---@type boolean, JoinDevicesResponse
      assert(ok, response)

      assert(response.success, response.errorMessage or vim.inspect(response))
      cb(response.records)
    end)
  )
end

return M
