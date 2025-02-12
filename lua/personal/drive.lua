local auv = require "personal.auv"
local co_resume = auv.co_resume
local google = require "personal.google"
local refresh_access_token = google.refresh_access_token
local get_token_info = google.get_token_info
local fs = vim.fs

local token_prefix = "turing-"

local mime = {
  png = "image/png",
  mp4 = "video/mp4",
}

---@class FileResponse
---@field id string
---@field kind "drive#file"
---@field mimeType string
---@field name string

---@param token_info TokenInfo
---@param file_name string
---@param name string?
---@return FileResponse?
local function upload_screenshot(token_info, file_name, name)
  local co = coroutine.running()

  local file_extension = vim.fn.fnamemodify(file_name, ":e")

  if not name then
    vim.ui.input(
      { prompt = "name", default = ("task13_step1_.%s"):format(file_extension) },
      function(input) co_resume(co, input) end
    )
    name = coroutine.yield() ---@type string|nil
    if not name then return end
  end

  local extension = vim.fn.fnamemodify(name, ":e")

  local file = io.open(file_name, "r")
  assert(file)
  local file_content = file:read "*a"
  file:close()

  local tmp_name = os.tmpname()
  local tmp_file = io.open(tmp_name, "w")
  assert(tmp_file)
  local data = ([[--foo
Content-Type: application/json; charset=UTF-8

%s

--foo
Content-Type: %s

%s
--foo--
]]):format(
    vim.json.encode {
      name = name,
      parents = { "1XdSAONKCW96NfsTOZYNFLEA8oNxAyZIL" },
    },
    mime[extension],
    file_content
  )
  tmp_file:write(data)
  tmp_file:close()

  vim.system({
    "curl",
    "--data-binary",
    ("@%s"):format(tmp_name),
    "--http1.1",
    "--silent",
    "--header",
    ("Authorization: Bearer %s"):format(token_info.access_token),
    "--header",
    "Content-type: multipart/related; boundary=foo",
    "--header",
    ("Content-Length: %d"):format(#data),
    "https://www.googleapis.com/upload/drive/v3/files?uploadType=multipart",
  }, { text = true }, function(result) co_resume(co, result) end)
  local result = coroutine.yield() ---@type vim.SystemCompleted

  assert(result.stderr == "", result.stderr)

  local ok, response = pcall(vim.json.decode, result.stdout) ---@type boolean, string|FileResponse|ApiErrorResponse
  assert(ok, response)
  ---@cast response -string

  if response.error then
    ---@cast response -FileResponse
    assert(response.error.status == "UNAUTHENTICATED", response.error.message)
    auv.schedule()
    local refreshed_token_info = refresh_access_token(token_info.refresh_token, token_prefix)
    return upload_screenshot(refreshed_token_info, file_name, name)
  end
  ---@cast response -ApiErrorResponse

  return response
end

local already_seen = {} ---@type table<string, boolean>

local w = assert(vim.uv.new_fs_event())
local path = "/home/luis/Descargas/screenshot"
local ok = w:start(path, {}, function(err, filename, events)
  if err then return vim.notify(err, vim.log.levels.ERROR) end

  if not filename then return end

  local fullpath = fs.normalize(fs.joinpath(path, filename))

  coroutine.wrap(function()
    local type ---@type 'changed' | 'created' | 'deleted'

    if events.rename then
      local staterr, _ = auv.fs_stat(fullpath)
      if staterr and staterr:find "^ENOENT:" then
        type = "deleted"
      else
        assert(not staterr, staterr)
        type = "created"
      end
    elseif events.change then
      type = "changed"
    end
    assert(type)

    if type ~= "created" or not (fullpath:find "%.png$" or fullpath:find "%.mp4$") or already_seen[fullpath] then
      return
    end
    already_seen[fullpath] = true

    local token_info = get_token_info(token_prefix)
    assert(token_info, "There is no token_info")
    auv.schedule()
    local file_response = upload_screenshot(token_info, fullpath)
    if not file_response then return end
    -- TODO: test if this may not work in some case (i.e. if I need to get the link in a different way)
    auv.schedule()
    vim.fn.setreg("+", ("https://drive.google.com/file/d/%s/view?usp=drive_link"):format(file_response.id))
    vim.system { "dunstify", "Document link has been put in the clipboard", "--timeout=600" }
  end)()
end)
if ok ~= 0 then return vim.notify "File watcher couldn't be started" end
vim.notify(("File watcher for dir `%s` was started"):format(path))

vim.keymap.set("n", "<F4>", function()
  local ok2 = w:stop()
  if ok2 ~= 0 then return vim.notify "File watcher couldn't be stopped" end
  vim.notify "File watcher removed"
  vim.keymap.del("n", "<F4>")
end)
