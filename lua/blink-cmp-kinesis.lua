--- @module 'blink.cmp'
--- @class blink.cmp.Source
local source = {}

function source.new(opts)
  local self = setmetatable({}, { __index = source })
  self.opts = opts
  return self
end

function source:enabled()
  return vim.bo.filetype == "kinesis"
end

local kinesis_keywords = {
  "t&h",
  "lalt",
  "lctrl",
  "lshift",
  "lwin",
  "ralt",
  "rctrl",
  "rwin",
  "rshift",
  "-lalt",
  "-lctrl",
  "-lshift",
  "-lwin",
  "-ralt",
  "-rctrl",
  "-rwin",
  "-rshift",
  "+lalt",
  "+lctrl",
  "+lshift",
  "+lwin",
  "+ralt",
  "+rctrl",
  "+rwin",
  "+rshift",
  "`",
  ";",
  [[\]],
  "/",
  "'",
  "'",
  [[intl-\]],
  "f1",
  "f2",
  "f3",
  "f4",
  "f5",
  "f6",
  "f7",
  "f8",
  "f9",
  "f10",
  "f11",
  "f12",
  "f13",
  "f14",
  "f15",
  "f16",
  "f17",
  "f18",
  "f19",
  "f20",
  "f21",
  "f22",
  "f23",
  "f24",
  "1",
  "2",
  "3",
  "4",
  "5",
  "6",
  "7",
  "8",
  "9",
  "0",
  "hyphen",
  "=",
  "a",
  "b",
  "c",
  "d",
  "e",
  "f",
  "g",
  "h",
  "i",
  "j",
  "k",
  "l",
  "m",
  "n",
  "o",
  "p",
  "q",
  "r",
  "s",
  "t",
  "u",
  "v",
  "w",
  "x",
  "y",
  "z",
  "obrack",
  "cbrack",
  "meh",
  "hyper",
  "next",
  "prev",
  "play",
  "mute",
  "vol+",
  "calc",
  "enter",
  "tab",
  "space",
  "delete",
  "bspace",
  "escape",
  "prtscr",
  "scroll",
  "caps",
  "insert",
  "pause",
  "menu",
  "kptoggle",
  "kpshift",
  "numlk",
  "kp0",
  "kp1",
  "kp3",
  "kp3",
  "kp4",
  "kp5",
  "kp6",
  "kp7",
  "kp8",
  "kp9",
  "kp.",
  "kpdiv",
  "kpplus",
  "kpmin",
  "kpmult",
  "kpenter1",
  "kp=mac",
  "shutdn",
  "lmouse",
  "rmouse",
  "mmouse",
  "left",
  "down",
  "right",
  "up",
  "pup",
  "pdown",
  "null",
  "home",
  "end",
}

function source:get_completions(ctx, callback)
  --- @type lsp.CompletionItem[]
  local items = vim
    .iter(kinesis_keywords)
    :map(function(keyword)
      return {
        label = keyword,
        kind = vim.lsp.protocol.CompletionItemKind.Keyword,
      }
    end)
    :totable()

  callback {
    items = items,
    is_incomplete_backward = false,
    is_incomplete_forward = false,
  }

  -- (Optional) Return a function which cancels the request
  -- If you have long running requests, it's essential you support cancellation
  return function() end
end

function source:execute(ctx, item, callback, default_implementation)
  default_implementation()

  callback()
end

return source
