local uv = vim.uv
local auv = require "personal.auv"
local co_resume = auv.co_resume

local l = vim.lpeg
local P, S, V, C, Cg, Cmt, Cb, Ct, R = l.P, l.S, l.V, l.C, l.Cg, l.Cmt, l.Cb, l.Ct, l.R

local alpha = R("az", "AZ")
local digit = R "09"
local alnum = alpha + digit
local unreserved = alnum + S "-_.~"

local sub_delims = S "!$&'()*+,;="

local hexdig = R "09" + R "AF"
local pct_encoded = P "%" * hexdig * hexdig

---@param pat vim.lpeg.Pattern
---@param min integer
---@param max integer
---@return vim.lpeg.Pattern
local function patcount(pat, min, max) return -pat ^ (max + 1) * pat ^ min end

-- stylua: ignore
local dec_octet = digit
+ R "19" * digit
+ P "1" * digit * digit
+ P "2" * R "04" * digit
+ P"25" * R "05"
local ipv4adress = dec_octet * P "." * dec_octet * P "." * dec_octet * P "." * dec_octet

local h16 = patcount(hexdig, 1, 4)
local h16c = h16 * P ":"
local ls32 = (h16 * P ":" * h16) + ipv4adress
local ipv6address = patcount(h16c, 6, 6) * ls32
  + P "::" * patcount(h16c, 5, 5) * ls32
  + h16 ^ -1 * P "::" * patcount(h16c, 4, 4) * ls32
  + (h16c ^ -1 * h16) ^ -1 * P "::" * patcount(h16c, 3, 3) * ls32
  + (h16c ^ -2 * h16) ^ -1 * P "::" * patcount(h16c, 2, 2) * ls32
  + (h16c ^ -3 * h16) ^ -1 * P "::" * h16c * ls32
  + (h16c ^ -4 * h16) ^ -1 * P "::" * ls32
  + (h16c ^ -5 * h16) ^ -1 * P "::" * h16
  + (h16c ^ -6 * h16) ^ -1 * P "::"

local ipvfuture = P "v" * hexdig ^ 1 * P "." * (unreserved + sub_delims + P ":") ^ 1
local ip_literal = P "[" * (ipv6address + ipvfuture) * P "]"

local reg_name = (unreserved + pct_encoded + sub_delims) ^ 0

local pchar = unreserved + pct_encoded + sub_delims + S ":@"
local path_empty = P(0)
local segment_nz_nc = (unreserved + pct_encoded + sub_delims + P "@") ^ 1
local segment_nz = pchar ^ 1
local segment = pchar ^ 0
local path_rootless = segment_nz * (P "/" * segment) ^ 0
local path_noscheme = segment_nz_nc * (P "/" * segment) ^ 0
local path_absolute = P "/" * (segment_nz * (P "/" * segment) ^ 0) ^ -1
local path_abempty = (P "/" * segment) ^ 0
-- local _path = path_abempty + path_absolute + path_noscheme + path_rootless + path_empty

-- local trace = require("personal.pegdebug").trace
---@diagnostic disable-next-line: missing-fields
local uri_grammar = P {
  "uri",
  scheme = Cg(alpha * (alnum + S "+-.") ^ 0, "scheme"),
  userinfo = Cg((unreserved + pct_encoded + sub_delims + P ":") ^ 0, "userinfo"),
  host = Cg(ip_literal + ipv4adress + reg_name, "host"),
  port = Cg(digit ^ 0 / tonumber, "port"),
  authority = Ct((V "userinfo" * P "@") ^ -1 * V "host" * (P ":" * V "port") ^ -1),
  hier_part = Cg(
    Ct(
      P "//" * Cg(V "authority", "authority") * Cg(path_abempty, "path")
        + Cg(path_absolute, "path")
        + Cg(path_rootless, "path")
        + Cg(path_noscheme, "path")
        + Cg(path_empty, "path")
    ),
    "hier_part"
  ),
  query = Cg((pchar + P "/" + P "?") ^ 0, "query"),
  fragment = Cg((pchar + P "/" + P "?") ^ 0, "fragment"),
  uri = Ct(V "scheme" * P ":" * V "hier_part" * (P "?" * V "query") ^ -1 * (P "#" * V "fragment") ^ -1 * -P(1)),
}

---@class http.Uri
---@field hier_part {authority: {host: string, userinfo: string}, path: string}
---@field port integer
---@field query string
---@field fragment string
---@field scheme string

---@param uri string
---@param headers table<string, string>|nil
---@return string
local function get(uri, headers)
  -- TODO: handle http vs https
  local co = coroutine.running()
  assert(co, "get must be called within a coroutine")

  local parsed_uri = assert(uri_grammar:match(uri)) ---@type http.Uri
  local host = assert(parsed_uri.hier_part.authority.host)
  local port = parsed_uri.port or 80 -- TODO: get default port from schema
  local path = assert(parsed_uri.hier_part.path)

  local resolved_host = uv.getaddrinfo(host, nil, {
    family = "inet",
    protocol = "tcp",
  })[1]

  assert(resolved_host, ("Host `%s`, can't be resolved to a valid IP address"):format(host))

  local headers_str = ""
  if headers then
    local headers_tbl = {} ---@type string[]
    for key, value in pairs(headers) do
      table.insert(headers_tbl, ("%s: %s"):format(key, value))
    end
    table.insert(headers_tbl, "\n")
    headers_str = table.concat(headers_tbl, "\n")
  end

  local client = assert(uv.new_tcp())
  client:connect(resolved_host.addr, port, function(err)
    assert(not err, err)
    co_resume(co)
  end)
  coroutine.yield()

  client:read_start(function(err, data)
    assert(not err, err)
    if not data then return end

    co_resume(co, data) -- will resume the last coroutine.yield, before returning from `get`
  end)

  local request = ([[GET %s HTTP/1.1
Host: %s
User-Agent: curl/8.12.0
Accept: */*
Connection: close
%s
]]):format(path, host, headers_str)
  request = request:gsub("\n", "\r\n")
  client:write(request, function(err)
    assert(not err, err)

    co_resume(co)
  end)
  coroutine.yield(co)

  -- TODO: parse response with lpeg
  local response = coroutine.yield() ---@type string
  client:read_stop()
  client:close()
  return response
end

local a = uri_grammar:match "https://google.com:80"
-- __AUTO_GENERATED_PRINT_VAR_START__
print([==[ a:]==], vim.inspect(a)) -- __AUTO_GENERATED_PRINT_VAR_END__

-- coroutine.wrap(function()
--   local result = get "http://httpbingo.org/get"
--   -- __AUTO_GENERATED_PRINT_VAR_START__
--   print([==[function result:]==], vim.inspect(result)) -- __AUTO_GENERATED_PRINT_VAR_END__
--   --
-- end)()
