local iter = vim.iter
local bit = require "bit"
local lshift, rshift, band, bor, bxor = bit.lshift, bit.rshift, bit.band, bit.bor, bit.bxor

local M = {}

local function random()
  local random_list = {} ---@type string[]
  for _ = 1, 4 do
    local number = math.random(0, 0xffffffff)

    local byte1 = rshift(number, 24)
    local byte2 = band(rshift(number, 16), 0x000000ff)
    local byte3 = band(rshift(number, 8), 0x000000ff)
    local byte4 = band(number, 0x000000ff)

    table.insert(random_list, string.char(byte1, byte2, byte3, byte4))
  end

  local random_32_bytes = table.concat(random_list, "")
  return random_32_bytes
end

-- Always takes 1 byte (because the enumeration uses numbers up to 255)
---@enum http.handshake_type
M.handshake_type = {
  client_hello = 1,
  server_hello = 2,
  new_session_ticket = 4,
  end_of_early_data = 5,
  encrypted_extensions = 8,
  certificate = 11,
  certificate_request = 13,
  certificate_verify = 15,
  finished = 20,
  key_update = 24,
  message_hash = 254,
}

---@enum http.cipher_suite
M.cipher_suite = {
  tls_aes_128_gcm_sha256 = string.char(0x13, 0x01),
  tls_aes_256_gcm_sha384 = string.char(0x13, 0x02),
  tls_chacha20_poly1305_sha256 = string.char(0x13, 0x03),
  tls_aes_128_ccm_sha256 = string.char(0x13, 0x04),
  tls_aes_128_ccm_8_sha256 = string.char(0x13, 0x05),
}

---@enum http.tls_version
M.tls_version = {
  _1_2 = string.char(0x03, 0x03),
  _1_3 = string.char(0x03, 0x04),
}

local order = 0xff
local irr_polynom = 0x11b
local log = {} ---@type table<integer, integer>
local exp = {} ---@type table<integer, integer>

---@param a integer
---@param b integer
local function polynom_add(a, b) return bxor(a, b) end

---@param a integer
---@param b integer
local function polynom_sub(a, b) return polynom_add(a, b) end

--
-- inverts element
-- a^(-1) = g^(order - log(a))
--
---@param a integer
---@return integer
local function polynom_invert(a)
  if a == 1 then return 1 end

  local exponent = order - log[a]
  return exp[exponent]
end

--
-- multiply two elements using a logarithm table
-- a*b = g^(log(a)+log(b))
--
---@param a integer
---@param b integer
---@return integer
local function polynom_mul(a, b)
  if a == 0 or b == 0 then return 0 end

  local exponent = log[a] + log[b]
  if exponent >= order then exponent = exponent - order end
  return exp[exponent]
end

--
-- divide two elements
-- a/b = g^(log(a)-log(b))
--
---@param a integer
---@param b integer
---@return integer
local function polynom_div(a, b)
  if a == 0 then return 0 end
  -- TODO: exception if operand2 == 0

  local exponent = log[a] - log[b]
  if exponent < 0 then exponent = exponent + order end
  return exp[exponent]
end

local a = 1
for i = 0, order - 1 do
  exp[i] = a
  log[a] = i

  -- multiply with generator x+1 -> left shift + 1
  a = bxor(lshift(a, 1), a)

  -- if a gets larger than order, reduce modulo irreducible polynom
  if a > order then a = polynom_sub(a, irr_polynom) end
end

--
-- calculate the parity of one byte
--
---@param byte integer
---@return integer
local function byte_parity(byte)
  byte = bxor(byte, bit.rshift(byte, 4))
  byte = bxor(byte, bit.rshift(byte, 2))
  byte = bxor(byte, bit.rshift(byte, 1))
  return bit.band(byte, 1)
end

---@param byte integer
---@return integer
local function affine_map(byte)
  local mask = 0xf8
  local result = 0
  for i = 1, 8 do
    result = lshift(result, 1)

    local parity = byte_parity(bit.band(byte, mask))
    result = result + parity

    -- simulate roll
    local lastbit = bit.band(mask, 1)
    mask = bit.band(bit.rshift(mask, 1), 0xff)
    if lastbit ~= 0 then
      mask = bit.bor(mask, 0x80)
    else
      mask = bit.band(mask, 0x7f)
    end
  end

  return bxor(result, 0x63)
end

local s_box = {} ---@type table<integer, integer>
local i_s_box = {} ---@type table<integer, integer>
for i = 0, 255 do
  local inverse ---@type integer
  if i == 0 then
    inverse = 0
  else
    inverse = polynom_invert(i)
  end
  local mapped = affine_map(inverse)
  s_box[i] = mapped
  i_s_box[mapped] = i
end

---@param a integer
---@return integer
local function xtime(a)
  if bit.band(a, 0x80) ~= 0 then return bit.band(bxor(lshift(a, 1), 0x1b), 0xff) end
  return lshift(a, 1)
end

-- rotate word: 0xaabbccdd gets 0xbbccddaa
-- used for key schedule
--
---@param word integer[]
---@return integer[]
local function rot_word(word) return { word[2], word[3], word[4], word[1] } end

-- replace all bytes in a word with the SBox.
-- used for key schedule
--
---@param word integer[]
---@return integer[]
local function sub_word(word)
  return iter(word):map(function(byte) return s_box[byte] end):totable()
end

local round_const = {
  { 0x01, 0x00, 0x00, 0x00 },
  { 0x02, 0x00, 0x00, 0x00 },
  { 0x04, 0x00, 0x00, 0x00 },
  { 0x08, 0x00, 0x00, 0x00 },
  { 0x10, 0x00, 0x00, 0x00 },
  { 0x20, 0x00, 0x00, 0x00 },
  { 0x40, 0x00, 0x00, 0x00 },
  { 0x80, 0x00, 0x00, 0x00 },
  { 0x1b, 0x00, 0x00, 0x00 },
  { 0x36, 0x00, 0x00, 0x00 },
  { 0x6c, 0x00, 0x00, 0x00 },
  { 0xd8, 0x00, 0x00, 0x00 },
  { 0xab, 0x00, 0x00, 0x00 },
  { 0x4d, 0x00, 0x00, 0x00 },
  { 0x9a, 0x00, 0x00, 0x00 },
  { 0x2f, 0x00, 0x00, 0x00 },
}

---@param state integer[][]
local function inv_byte_sub(state)
  for _, col in ipairs(state) do
    for i, byte in ipairs(col) do
      col[i] = i_s_box[byte]
    end
  end
end

---@param state integer[][]
local function byte_sub(state)
  for _, col in ipairs(state) do
    for i, byte in ipairs(col) do
      col[i] = s_box[byte]
    end
  end
end

---@param state integer[][]
---@param n_columns integer
local function mix_column(state, n_columns)
  for i = 1, n_columns do
    local bytes = state[i]

    local t = bxor(bytes[1], bytes[2], bytes[3], bytes[4])
    local u = bytes[1]
    bytes[1] = bxor(bytes[1], t, xtime(bxor(bytes[1], bytes[2])))
    bytes[2] = bxor(bytes[2], t, xtime(bxor(bytes[2], bytes[3])))
    bytes[3] = bxor(bytes[3], t, xtime(bxor(bytes[3], bytes[4])))
    bytes[4] = bxor(bytes[4], t, xtime(bxor(bytes[4], u)))
  end
end

---@param state integer[][]
---@param n_columns integer
local function inv_mix_column(state, n_columns)
  for i = 1, n_columns do
    local bytes = state[i]

    local u = xtime(xtime(bxor(bytes[1], bytes[3])))
    local v = xtime(xtime(bxor(bytes[2], bytes[4])))
    bytes[1] = bxor(bytes[1], u)
    bytes[2] = bxor(bytes[2], v)
    bytes[3] = bxor(bytes[3], u)
    bytes[4] = bxor(bytes[4], v)
  end
  mix_column(state, n_columns)
end

---@param state integer[][]
---@param n_columns integer
---@return integer[][]
local function inv_shift_row(state, n_columns)
  local offset2 = n_columns == 4 and 1 or n_columns == 6 and 1 or n_columns == 8 and 1
  local offset3 = n_columns == 4 and 2 or n_columns == 6 and 2 or n_columns == 8 and 3
  local offset4 = n_columns == 4 and 3 or n_columns == 6 and 3 or n_columns == 8 and 4

  local shifted = {} ---@type integer[][]
  for i = 1, n_columns do
    local col2 = i - offset2
    if col2 <= 0 then col2 = col2 + n_columns end
    local col3 = i - offset3
    if col3 <= 0 then col3 = col3 + n_columns end
    local col4 = i - offset4
    if col4 <= 0 then col4 = col4 + n_columns end
    shifted[i] = {
      state[i][1],
      state[col2][2],
      state[col3][3],
      state[col4][4],
    }
  end
  return shifted
end

---@param state integer[][]
---@param n_columns integer
---@return integer[][]
local function shift_row(state, n_columns)
  local offset2 = n_columns == 4 and 1 or n_columns == 6 and 1 or n_columns == 8 and 1
  local offset3 = n_columns == 4 and 2 or n_columns == 6 and 2 or n_columns == 8 and 3
  local offset4 = n_columns == 4 and 3 or n_columns == 6 and 3 or n_columns == 8 and 4

  local shifted = {} ---@type integer[][]
  for i = 1, n_columns do
    local col2 = i + offset2
    if col2 > n_columns then col2 = col2 - n_columns end
    local col3 = i + offset3
    if col3 > n_columns then col3 = col3 - n_columns end
    local col4 = i + offset4
    if col4 > n_columns then col4 = col4 - n_columns end
    shifted[i] = {
      state[i][1],
      state[col2][2],
      state[col3][3],
      state[col4][4],
    }
  end
  return shifted
end

---@param state integer[][]
---@param key_schedule integer[][]
---@return integer[][]
local function add_round_key(state, n_columns_key, round, key_schedule)
  return iter(ipairs(state))
    :map(function(i, col)
      return iter(ipairs(col))
        :map(function(j, byte)
          local round_key_col = key_schedule[i + n_columns_key * round]
          local round_key_byte = round_key_col[j]
          return bxor(byte, round_key_byte)
        end)
        :totable()
    end)
    :totable()
end

---@param cipher_key integer[][]
---@param n_columns integer
---@param n_columns_key integer
---@param n_rounds integer
---@return integer[][]
local function expand_cipher_key(cipher_key, n_columns, n_columns_key, n_rounds)
  local key_schedule = {} ---@type integer[][]
  if n_columns_key < 6 then
    for i, col in ipairs(cipher_key) do
      key_schedule[i] = col
    end
    for i = n_columns_key + 1, n_columns * (n_rounds + 1) do
      local temp = key_schedule[i - 1]
      if ((i - 1) % n_columns_key) == 0 then
        temp = iter(ipairs(sub_word(rot_word(temp))))
          :map(function(j, byte) return bxor(byte, round_const[(i - 1) / n_columns_key][j]) end)
          :totable()
      end
      key_schedule[i] = iter(ipairs(key_schedule[i - n_columns_key]))
        :map(function(j, byte) return bxor(byte, temp[j]) end)
        :totable()
    end
  else
    for i, col in ipairs(cipher_key) do
      key_schedule[i] = col
    end
    for i = n_columns_key + 1, n_columns * (n_rounds + 1) do
      local temp = key_schedule[i - 1]
      if ((i - 1) % n_columns_key) == 0 then
        temp = iter(ipairs(sub_word(rot_word(temp))))
          :map(function(j, byte) return bxor(byte, round_const[(i - 1) / n_columns_key][j]) end)
          :totable()
      elseif ((i - 1) % n_columns_key) == 4 then
        temp = sub_word(temp) -- this is the only different line
      end
      key_schedule[i] = iter(ipairs(key_schedule[i - n_columns_key]))
        :map(function(j, byte) return bxor(byte, temp[j]) end)
        :totable()
    end
  end
  return key_schedule
end

---@param block_length integer 128|192|256
---@param key_length integer 128|192|256
---@param key string
---@param plaintext string
---@return tls.Bytes16
local function aes_encrypt(block_length, key_length, key, plaintext)
  local n_columns = block_length / 32 -- Nb
  local n_columns_key = key_length / 32 -- Nk

  -- Nr
  local n_rounds = (n_columns == 8 or n_columns_key == 8) and 14
    or (n_columns == 6 or n_columns_key == 6) and 12
    or (n_columns == 4 and n_columns_key == 4) and 10
    or nil
  assert(n_rounds)

  local state = {} ---@type integer[][]
  for i = 1, n_columns do
    local byte1 = plaintext:sub(i * 4 - 3, i * 4 - 3):byte()
    local byte2 = plaintext:sub(i * 4 - 2, i * 4 - 2):byte()
    local byte3 = plaintext:sub(i * 4 - 1, i * 4 - 1):byte()
    local byte4 = plaintext:sub(i * 4, i * 4):byte()

    table.insert(state, { byte1, byte2, byte3, byte4 })
  end

  local cipher_key = {} ---@type integer[][]
  for i = 1, n_columns_key do
    local byte1 = key:sub(i * 4 - 3, i * 4 - 3):byte()
    local byte2 = key:sub(i * 4 - 2, i * 4 - 2):byte()
    local byte3 = key:sub(i * 4 - 1, i * 4 - 1):byte()
    local byte4 = key:sub(i * 4, i * 4):byte()

    table.insert(cipher_key, { byte1, byte2, byte3, byte4 })
  end

  ---@type integer[][]
  state = iter(ipairs(state))
    :map(function(i, col)
      return iter(ipairs(col)):map(function(j, byte) return bxor(byte, cipher_key[i][j]) end):totable()
    end)
    :totable()

  local key_schedule = expand_cipher_key(cipher_key, n_columns, n_columns_key, n_rounds)

  for round = 1, n_rounds - 1 do
    byte_sub(state)

    state = shift_row(state, n_columns)

    mix_column(state, n_columns)

    state = add_round_key(state, n_columns_key, round, key_schedule)
  end

  byte_sub(state)

  state = shift_row(state, n_columns)

  local round = n_rounds
  state = add_round_key(state, n_columns_key, round, key_schedule)

  -- TODO: what is the correct interface for both if this functions? return integer[][]?
  local out = {} ---@type integer[]
  for i = 1, n_columns do
    for _, byte in ipairs(state[i]) do
      table.insert(out, byte)
    end
  end
  return out
end

---@param block_length integer 128|192|256
---@param key_length integer 128|192|256
---@param key string
---@param ciphered_text integer[]
local function aes_decrypt(block_length, key_length, key, ciphered_text)
  local n_columns = block_length / 32 -- Nb
  local n_columns_key = key_length / 32 -- Nk

  -- Nr
  local n_rounds = (n_columns == 8 or n_columns_key == 8) and 14
    or (n_columns == 6 or n_columns_key == 6) and 12
    or (n_columns == 4 and n_columns_key == 4) and 10
    or nil
  assert(n_rounds)

  local state = {} ---@type integer[]
  for i = 1, n_columns do
    local byte1 = ciphered_text[i * 4 - 3]
    local byte2 = ciphered_text[i * 4 - 2]
    local byte3 = ciphered_text[i * 4 - 1]
    local byte4 = ciphered_text[i * 4]

    table.insert(state, { byte1, byte2, byte3, byte4 })
  end

  local cipher_key = {} ---@type integer[][]
  for i = 1, n_columns_key do
    local byte1 = key:sub(i * 4 - 3, i * 4 - 3):byte()
    local byte2 = key:sub(i * 4 - 2, i * 4 - 2):byte()
    local byte3 = key:sub(i * 4 - 1, i * 4 - 1):byte()
    local byte4 = key:sub(i * 4, i * 4):byte()

    table.insert(cipher_key, { byte1, byte2, byte3, byte4 })
  end

  local key_schedule = expand_cipher_key(cipher_key, n_columns, n_columns_key, n_rounds)

  local round = n_rounds
  state = add_round_key(state, n_columns_key, round, key_schedule)

  state = inv_shift_row(state, n_columns)

  inv_byte_sub(state)

  for round = n_rounds - 1, 1, -1 do
    state = add_round_key(state, n_columns_key, round, key_schedule)

    inv_mix_column(state, n_columns)

    state = inv_shift_row(state, n_columns)

    inv_byte_sub(state)
  end

  ---@type integer[][]
  state = iter(ipairs(state))
    :map(function(i, col)
      return iter(ipairs(col)):map(function(j, byte) return bxor(byte, cipher_key[i][j]) end):totable()
    end)
    :totable()

  local out = {} ---@type string[]
  for i = 1, n_columns do
    for _, byte in ipairs(state[i]) do
      table.insert(out, bit.tohex(byte, 2))
    end
  end
  return out
end

local encrypted = aes_encrypt(128, 128, "1234567890123456", "algo            ")
local decrypted = aes_decrypt(128, 128, "1234567890123456", encrypted)

local aux = iter(decrypted):map(function(char) return string.char(tonumber(char, 16)) end):join ""
-- __AUTO_GENERATED_PRINT_VAR_START__
print([==[ aux:]==], vim.inspect(aux)) -- __AUTO_GENERATED_PRINT_VAR_END__

-- GF(2^128) defined by 1 + a + a^2 + a^7 + a^128
---@param x tls.Bytes4
---@param y tls.Bytes4
---@return tls.Bytes4
local function gf_2_128_mul(x, y)
  local v = vim.deepcopy(x)

  local r = { 0xE1000000, 0x00000000, 0x00000000, 0x00000000 }

  -- z
  ---@type integer[]
  local out = { 0x00000000, 0x00000000, 0x00000000, 0x00000000 }

  -- TODO: maybe implement this more efficiently
  for i = 1, 128 do
    local int_i = math.ceil(i / 4)
    local bit_offset = (32 - (i % 32)) % 32

    local one_bit_mask = 1
    local y_i_bit = band(rshift(y[int_i], bit_offset), one_bit_mask)
    if y_i_bit == 1 then
      out = iter(ipairs(out)):map(function(i, byte) return bxor(byte, x[i]) end):totable() --[=[@as integer[]]=]
    end

    local v_last_bit = band(rshift(v[#v], 7), one_bit_mask)
    -- always rshift (after getting the last bit)
    v = iter(ipairs(v))
      :map(function(i, byte)
        local previous_byte = v[i - i] or 0
        local two_bytes = lshift(previous_byte, 8) + byte --[[@as integer]]
        local one_byte_mask = 0xff
        return band(rshift(two_bytes, 1), one_byte_mask)
      end)
      :totable() --[=[@as integer[]]=]
    if v_last_bit == 1 then
      -- there's no need to xor each byte because all but the first one are 0x00000000
      v[1] = bxor(v[1], r[1])
    end
  end

  return out
end

-- TODO: maybe implement lookup tables for multiplying for the key (to make it
-- faster) reference:
-- https://github.com/bozhu/AES-GCM-Python/blob/master/aes_gcm.py#L32

---@param bytes integer[] up to 128 bits
---@param n integer number of most-significant bits to take
---@return integer[] #up to 128 bites
local function msb(bytes, n)
  assert(n <= #bytes * 8)

  local whole_bytes_num = math.floor(n / 8)
  local bits_last_num = n % 8
  local whole_bytes_int_num = math.floor(whole_bytes_num / 4)
  local bytes_in_whole_int_num = whole_bytes_int_num * 4

  local nums ---@type tls.Bytes4
  if #bytes == 4 then
    ---@cast bytes -tls.Bytes16
    nums = bytes
  else
    nums = {}
    for i = 1, whole_bytes_int_num do
      local byte1 = bytes[i * 4 - 3]
      local byte2 = bytes[i * 4 - 2]
      local byte3 = bytes[i * 4 - 1]
      local byte4 = bytes[i * 4]

      local num = bor(lshift(byte1, 24), lshift(byte2, 16), lshift(byte3, 8), byte4)
      table.insert(nums, num)
    end
  end

  if whole_bytes_num ~= bytes_in_whole_int_num or bits_last_num ~= 0 then
    local last_byte = 0
    for i = bytes_in_whole_int_num + 1, whole_bytes_num do
      local byte = bytes[i]
      local relative_i = whole_bytes_num - i
      local offset = relative_i * 8 + bits_last_num
      last_byte = bor(last_byte, lshift(byte, offset))
    end

    if bits_last_num ~= 0 then
      local byte = bytes[whole_bytes_num + 1]
      -- TODO: I'm aligning the bits to the right, I may want to align them to the left (?
      local offset = 8 - bits_last_num
      last_byte = bor(last_byte, rshift(byte, offset))
    end

    table.insert(nums, last_byte)
  end

  return nums
end

local two_pow_32 = 2 ^ 32
---@param value integer[]
local function incr(value)
  ---@type integer
  local rightmost_32_num = iter(ipairs(value))
    :filter(function(i) return i > (#value - 32 / 8) end)
    :fold(0, function(acc, i, a) return acc + lshift(a, (4 - i) * 8) end)
  rightmost_32_num = (rightmost_32_num + 1) % two_pow_32

  local byte1 = rshift(rightmost_32_num, 24)
  local byte2 = band(rshift(rightmost_32_num, 16), 0x000000ff)
  local byte3 = band(rshift(rightmost_32_num, 8), 0x000000ff)
  local byte4 = band(rightmost_32_num, 0x000000ff)

  value[#value - 3] = byte1
  value[#value - 2] = byte2
  value[#value - 1] = byte3
  value[#value] = byte4
  return value
end

---@class tls.Bytes4
---@field [1] integer
---@field [2] integer
---@field [3] integer
---@field [4] integer

---@class tls.Bytes16
---@field [1] integer
---@field [2] integer
---@field [3] integer
---@field [4] integer
---@field [5] integer
---@field [6] integer
---@field [7] integer
---@field [8] integer
---@field [9] integer
---@field [10] integer
---@field [11] integer
---@field [12] integer
---@field [13] integer
---@field [14] integer
---@field [15] integer
---@field [16] integer

---@param initial_tag tls.Bytes4
---@param aad string
---@param ciphered tls.Bytes4
---@param number_of_blocks_aad integer
---@param number_of_blocks integer
---@return tls.Bytes4
local function ghash(initial_tag, aad, ciphered, number_of_blocks_aad, number_of_blocks)
  local bits_num = 128
  local bytes_num = bits_num / 8

  local total_bits_aad = #aad * 8

  -- v
  local last_block_length_aad = (total_bits_aad % bits_num) + 1

  ---@type tls.Bytes4
  local x = { 0x00000000, 0x00000000, 0x00000000, 0x00000000 }

  for i = 1, number_of_blocks_aad - 1 do
    local aad_segment = aad:sub(bytes_num * (i - 1) + 1, bytes_num * i)
    ---@type tls.Bytes16|tls.Bytes4
    local aad_block = iter(vim.split(aad_segment, "")):map(function(char) return char:byte() end):totable()
    aad_block = msb(aad_block, bits_num)

    x = iter(ipairs(aad_block)):map(function(i, byte) return bxor(byte, x[i]) end):totable()
    x = gf_2_128_mul(x, initial_tag)
  end

  -- i = m
  local aad_segment = aad:sub(bytes_num * (number_of_blocks_aad - 1) + 1, bytes_num * number_of_blocks_aad)
  local aad_block = iter(vim.split(aad_segment, "")):map(function(char) return char:byte() end):totable() ---@type integer[]
  local padding_bits = 128 - last_block_length_aad
  local padding_bytes = padding_bits / 8
  for _ = 1, padding_bytes do
    table.insert(aad_block, 0)
  end
  x = iter(ipairs(aad_block)):map(function(i, byte) return bxor(byte, x[i]) end):totable()
  x = gf_2_128_mul(x, initial_tag)

  for i = number_of_blocks_aad + 1, number_of_blocks_aad + number_of_blocks - 1 do
    -- x =
  end

  -- i = m + n
  -- x =

  -- i = m + n + 1
  -- x =

  return x
end

---@param k string secret key (with appropriate length for the underlying block cipher)
---@param p string plaintext
---@param aad string aditional authenticated data
---@param iv integer[] initialization vector (a nonce) 96-bits
---@return string c ciphertext
---@return string t authentication tag, its length must be 128, 120, 112, 104, or 96
local function gcm_encrypt(k, p, aad, iv)
  local bits_num = 128
  local bytes_num = bits_num / 8

  -- TODO: zero pad p and aad

  local total_bits_plaintext = #p * 8
  -- n
  local number_of_blocks_plaintext = math.ceil(total_bits_plaintext / bits_num)
  -- u
  local last_block_length_plaintext = (total_bits_plaintext % bits_num) + 1

  local total_bits_aad = #aad * 8
  -- m
  local number_of_blocks_aad = math.ceil(total_bits_aad / bits_num)
  -- v
  local last_block_length_aad = (total_bits_aad % bits_num) + 1

  local zeroes = string.char(0):rep(bits_num / 8)
  -- H
  local initial_tag = aes_encrypt(bits_num, bits_num, k, zeroes)
  initial_tag = msb(initial_tag, bits_num)

  -- t
  local authentication_tag_length = 0 -- TODO: is this 128?

  -- y0
  local initial_counter = iv
  table.insert(initial_counter, string.char(0))
  table.insert(initial_counter, string.char(0))
  table.insert(initial_counter, string.char(0))
  table.insert(initial_counter, string.char(1))
  local counter = initial_counter

  local ciphered = {} ---@type integer[] list of 32 bit / 4 byte integers

  for i = 1, number_of_blocks_plaintext - 1 do
    -- yi
    counter = incr(counter)
    local encrypted_counter = aes_encrypt(bits_num, bits_num, k, string.char(unpack(counter)))

    local plaintext_segment = p:sub(bytes_num * (i - 1) + 1, bytes_num * i)
    -- pi
    ---@type tls.Bytes16
    local plaintext_block = iter(vim.split(plaintext_segment, "")):map(function(char) return char:byte() end):totable()

    -- ci
    ---@type integer[]
    local ciphered_block = iter(ipairs(plaintext_block))
      :map(function(i, byte) return bxor(byte, encrypted_counter[i]) end)
      :totable()

    ciphered_block = msb(ciphered_block, bits_num)

    vim.list_extend(ciphered, ciphered_block)
  end

  counter = incr(counter)
  local encrypted_counter = aes_encrypt(bits_num, bits_num, k, string.char(unpack(counter)))
  encrypted_counter = msb(encrypted_counter, last_block_length_plaintext)

  local plaintext_segment =
    p:sub(bytes_num * (number_of_blocks_plaintext - 1) + 1, bytes_num * number_of_blocks_plaintext)
  local plaintext_block = iter(vim.split(plaintext_segment, "")):map(function(char) return char:byte() end):totable() --[[@as tls.Bytes16]]
  plaintext_block = msb(plaintext_block, last_block_length_plaintext)

  ---@type tls.Bytes4
  local last_ciphered_block = iter(ipairs(plaintext_block))
    :map(function(i, byte) return bxor(byte, encrypted_counter[i]) end)
    :totable()

  vim.list_extend(ciphered, last_ciphered_block)

  local initial_counter_s = string.char(unpack(initial_counter))
  local encrypted_initial_counter = aes_encrypt(bits_num, bits_num, k, initial_counter_s)
  encrypted_initial_counter = msb(encrypted_initial_counter, 128)

  local hashed = ghash(initial_tag, aad, ciphered, number_of_blocks_aad, number_of_blocks_plaintext)
  local tag = iter(ipairs(encrypted_initial_counter)):map(function(i, a) return bxor(a, hashed[i]) end):totable() ---@type tls.Bytes4
  tag = msb(tag, authentication_tag_length)

  return ciphered, tag
end

---@param k string
---@param aad string
---@param iv string
---@param c string
---@param t string
---@return string p
local function gcm_decrypt(k, aad, iv, c, t) end

---@param str string
local function to_hex(str)
  local out = {} ---@type string[]
  for i = 1, #str do
    local byte = str:sub(i, i):byte()
    table.insert(out, bit.tohex(byte, 2))
  end
  return table.concat(out)
end

-- key in hex: 31323334353637383930313233343536
-- text in hex: 616c676f202020202020202020202020
-- encrypted in hex: 1a1f74115e439103990da1b5e66bb215

-- block chiper: AES-128
---@param p string plaintext
---@param aad string aditional authenticated data
---@param iv string initialization vector (a nonce)
---@return string c ciphertext
---@return string t authentication tag
local function aes_128_gcm_sha256(p, aad, iv) end

local function tls(uri)
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

  local legacy_version = M.tls_version._1_2
  local random_32_bytes = random()
  local legacy_session_id = "\0"
  local cipher_suite = table.concat {
    M.cipher_suite.tls_aes_128_gcm_sha256,
    M.cipher_suite.tls_aes_256_gcm_sha384,
    M.cipher_suite.tls_chacha20_poly1305_sha256,
    M.cipher_suite.tls_aes_128_ccm_sha256,
    M.cipher_suite.tls_aes_128_ccm_8_sha256,
  }
  local legacy_compression_methods = "\0"
  -- tls extensions
  local supported_versions = M.tls_version._1_3
  local request = (string.rep("%s", 6)):format(
    legacy_version,
    random_32_bytes,
    legacy_session_id,
    cipher_suite,
    legacy_compression_methods,
    supported_versions
  )
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

-- tls "https://httbingo.org/get"

return M
