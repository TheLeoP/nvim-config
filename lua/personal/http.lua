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

local query = Cg((pchar + P "/" + P "?") ^ 0, "query")
local _host = Cg(ip_literal + ipv4adress + reg_name, "host")
local _port = Cg(digit ^ 0 / tonumber, "port")

local scheme = Cg(alpha * (alnum + S "+-.") ^ 0, "scheme")
local userinfo = Cg((unreserved + pct_encoded + sub_delims + P ":") ^ 0, "userinfo")
local authority = Ct((userinfo * P "@") ^ -1 * _host * (P ":" * _port) ^ -1)
local hier_part = Cg(
  Ct(
    P "//" * Cg(authority, "authority") * Cg(path_abempty, "path")
      + Cg(path_absolute, "path")
      + Cg(path_rootless, "path")
      + Cg(path_noscheme, "path")
      + Cg(path_empty, "path")
  ),
  "hier_part"
)

-- local trace = require("personal.pegdebug").trace
---@diagnostic disable-next-line: missing-fields
local uri_grammar = P {
  "uri",
  scheme = scheme,
  userinfo = userinfo,
  host = _host,
  port = _port,
  authority = authority,
  hier_part = hier_part,
  query = query,
  fragment = Cg((pchar + P "/" + P "?") ^ 0, "fragment"),
  uri = Ct(V "scheme" * P ":" * V "hier_part" * (P "?" * V "query") ^ -1 * (P "#" * V "fragment") ^ -1 * -P(1)),
}

local crlf = P "\r\n"
local sp = P " "
local htab = P "\t"

local tchar = S "!#$%&'*+-.^_`|~" + digit + alpha
local token = tchar ^ 1

local absolute_path = (P "/" * segment) ^ 1
local absolute_URI = scheme * P ":" * hier_part * (P "?" * query) ^ -1

local status_code = patcount(digit, 3, 3)
local vchar = R "!~"
local obs_text = R "\128\255"

local ows = (sp + htab) ^ 0
local rws = (sp + htab) ^ 1
local bws = ows

local field_vchar = vchar + obs_text
local field_content = field_vchar * ((sp + htab + field_vchar) ^ 1 - ((sp + htab) * crlf)) ^ -1
local field_value = field_content ^ 0

local field_name = token

local octet = P(1)

-- local trace = require("personal.pegdebug").trace
---@diagnostic disable-next-line: missing-fields
local http_grammar = P {
  "message",
  message_body = Cg(octet ^ 0, "body"),
  field_value = field_value,
  field_line = C(field_name) * P ":" * ows * C(field_value) * ows,
  reason_phrase = (htab + sp + vchar + obs_text) ^ 1,
  status_line = Ct(
    V "http_version" * sp * Cg(status_code / tonumber, "code") * sp * Cg(V "reason_phrase", "status") ^ -1
  ),
  http_name = S "Hh" * S "Tt" * S "Tt" * S "Pp",
  http_version = V "http_name" * P "/" * Cg(digit * P "." * digit, "version"),
  asterisk_form = P "*",
  authority_form = _host * P ":" * _port,
  absolute_form = absolute_URI,
  origin_form = absolute_path * (P "?" * query) ^ -1,
  request_target = V "origin_form" + V "absolute_form" + V "authority_form" + V "asterisk_form",
  method = token,
  request_line = Ct(Cg(V "method", "method") * sp * Cg(V "request_target", "target") * sp * V "http_version"),
  start_line = Cg(V "request_line", "request") + Cg(V "status_line", "status"),
  message = Ct(
    V "start_line"
      * crlf
      * Cg(Ct "" * ((V "field_line" * crlf) % rawset) ^ 0, "headers")
      * crlf
      * V "message_body" ^ -1
      * P(-1)
  ),
}

---@class http.Status
---@field code integer
---@field status string
---@field version string

---@class http.Request
---@field method string
---@field target string
---@field version string

---@class http.Response
---@field request http.Request
---@field headers table<string, string>
---@field body string

---@class http.Authority
---@field host string
---@field userinfo string

---@class http.HierPart
---@field authority http.Authority
---@field path string

---@class http.Uri
---@field hier_part http.HierPart
---@field port integer
---@field query string
---@field fragment string
---@field scheme string

---@type table<string, integer>
local port_by_scheme = {
  http = 80,
  https = 443,
}

---@async
---@param uri string
---@param headers table<string, string>|nil
---@return http.Response
local function get(uri, headers)
  -- TODO: handle http vs https
  local co = coroutine.running()
  assert(co, "get must be called within a coroutine")

  local parsed_uri = assert(uri_grammar:match(uri)) ---@type http.Uri
  local host = assert(parsed_uri.hier_part.authority.host)
  local port = parsed_uri.port or port_by_scheme[parsed_uri.scheme]
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

  local response = coroutine.yield() ---@type string
  client:read_stop()
  client:close()
  return http_grammar:match(response)
end
