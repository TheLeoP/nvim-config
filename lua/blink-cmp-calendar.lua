local api = vim.api
local iter = vim.iter
local google = require "personal.google"
local get_token_info = google.get_token_info
local calendar = require "personal.calendar"
local sep = calendar.sep

--- @module 'blink.cmp'
--- @class blink.cmp.Source
local source = {}

function source.new(opts)
  local self = setmetatable({}, { __index = source })
  self.opts = opts
  return self
end

function source:enabled()
  local buf_name = api.nvim_buf_get_name(0)
  return buf_name:match "^calendar://"
end

local noop = function() end

-- TODO: return cancelation function for calendar request?
function source:get_completions(ctx, callback)
  -- TODO: is it ok to not give any completions if the current entry already contains an id?
  if ctx.line:match "^/[^ ]+ " then
    callback()
    return noop
  end

  local fields = vim.split(ctx.line, sep, { trimempty = true })
  local _, sep_num = ctx.line:gsub(sep, "")
  -- TODO: increase maximum?
  if sep_num == 0 or sep_num > 4 then
    callback()
    return noop
  end

  local recurrence_field = (fields[3] and fields[3]:match "^%d") and (fields[5] or "") or (fields[3] or "")
  local current_propertie = recurrence_field:match "(%w+):[^ ]*$"
  local current_rule = recurrence_field:match "(%w+)=[^=; ]*$"

  if sep_num == 1 or sep_num == 3 then
    coroutine.wrap(function()
      local token_info = get_token_info()
      if not token_info then
        callback()
        return noop
      end
      local calendar_list = calendar.get_calendar_list(token_info, {})

      local items = iter(calendar_list.items)
        :filter(
          ---@param calendar CalendarListEntry
          function(calendar)
            return calendar.accessRole ~= "reader"
          end
        )
        :map(
          ---@param calendar CalendarListEntry
          function(calendar)
            return {
              label = calendar.summary,
              documentation = calendar.description,
              kind = vim.lsp.protocol.CompletionItemKind.EnumMember,
            }
          end
        )
        :totable()
      callback {
        items = items,
        is_incomplete_backward = false,
        is_incomplete_forward = false,
      }
    end)()
  elseif (sep_num == 2 or sep_num == 4) and not current_propertie then
    local properties = {} ---@type string[]
    if not recurrence_field:match "RRULE" then table.insert(properties, "RRULE") end
    if not recurrence_field:match "RDATE" then table.insert(properties, "RDATE") end
    if not recurrence_field:match "EXDATE" then table.insert(properties, "EXDATE") end
    callback {
      items = iter(properties)
        :map(function(field)
          return { label = field, kind = vim.lsp.protocol.CompletionItemKind.EnumMember }
        end)
        :totable(),
      is_incomplete_backward = false,
      is_incomplete_forward = false,
    }
  elseif (sep_num == 2 or sep_num == 4) and current_propertie == "RRULE" and not current_rule then
    local rules = {} ---@type {[1]: string, [2]: string}[]
    if not recurrence_field:match "FREQ" then
      table.insert(rules, {
        "FREQ",
        "Identifies the type of recurrence rule. This rule part **MUST** be specified in the recurrence rule. Valid values include SECONDLY, to specify repeating events based on an interval of a second or more; MINUTELY, to specify repeating events based on an interval of a minute or more; HOURLY, to specify repeating events based on an interval of an hour or more; DAILY, to specify repeating events based on an interval of a day or more; WEEKLY, to specify repeating events based on an interval of a week or more; MONTHLY, to specify repeating events based on an interval of a month or more; and YEARLY, to specify repeating events based on an interval of a year or more.",
      })
    end
    -- TODO:  remove until because it depends on the end date? I guess I would need a new field for the end date
    if not recurrence_field:match "COUNT" and not recurrence_field:match "UNTIL" then
      table.insert(rules, {
        "COUNT",
        'Defines the number of occurrences at which to range-bound the recurrence. The "DTSTART" property value always counts as the first occurrence. ',
      })
      table.insert(rules, {
        "UNTIL",
        'Defines a DATE or DATE-TIME value that bounds the recurrence rule in an inclusive manner. If the value specified by UNTIL is synchronized with the specified recurrence, this DATE or DATE-TIME becomes the last instance of the recurrence. The value of the UNTIL rule part **MUST** have the same value type as the "DTSTART" property. Furthermore, if the "DTSTART" property is specified as a date with local time, then the UNTIL rule part **MUST** also be specified as a date with local time. If the "DTSTART" property is specified as a date with UTC time or a date with local time and time zone reference, then the UNTIL rule part **MUST** be specified as a date with UTC time. In the case of the "STANDARD" and "DAYLIGHT" sub-components the UNTIL rule part **MUST** always be specified as a date with UTC time. If specified as a DATE-TIME value, then it **MUST** be specified in a UTC time format. If not present, and the COUNT rule part is also not present, the "RRULE" is considered to repeat forever. ',
      })
    end
    if not recurrence_field:match "INTERVAL" then
      table.insert(rules, {
        "INTERVAL",
        'Contains a positive integer representing at which intervals the recurrence rule repeats. The default value is "1", meaning every second for a **SECONDLY** rule, every minute for a **MINUTELY** rule, every hour for an **HOURLY** rule, every day for a **DAILY** rule, every week for a **WEEKLY** rule, every month for a **MONTHLY** rule, and every year for a **YEARLY** rule. For example, within a **DAILY** rule, a value of "8" means every eight days. ',
      })
    end
    if not recurrence_field:match "BYSECOND" then
      table.insert(rules, {
        "BYSECOND",
        'Specifies a COMMA-separated list of seconds within a minute. Valid values are 0 to 60. The BYSECOND, BYMINUTE and BYHOUR rule parts **MUST NOT** be specified when the associated "DTSTART" property has a DATE value type. These rule parts **MUST** be ignored in RECUR value that violate the above requirement (e.g., generated by applications that pre-date this revision of iCalendar).',
      })
    end
    if not recurrence_field:match "BYMINUTE" then
      table.insert(rules, {
        "BYMINUTE",
        'The BYMINUTE rule part specifies a COMMA-separated list of minutes within an hour. Valid values are 0 to 59. The BYSECOND, BYMINUTE and BYHOUR rule parts **MUST NOT** be specified when the associated "DTSTART" property has a DATE value type. These rule parts **MUST** be ignored in RECUR value that violate the above requirement (e.g., generated by applications that pre-date this revision of iCalendar).',
      })
    end
    if not recurrence_field:match "BYHOUR" then
      table.insert(rules, {
        "BYHOUR",
        'The BYHOUR rule part specifies a COMMA- separated list of hours of the day. Valid values are 0 to 23. The BYSECOND, BYMINUTE and BYHOUR rule parts **MUST NOT** be specified when the associated "DTSTART" property has a DATE value type. These rule parts **MUST** be ignored in RECUR value that violate the above requirement (e.g., generated by applications that pre-date this revision of iCalendar).',
      })
    end
    if not recurrence_field:match "BYDAY" then
      table.insert(rules, {
        "BYDAY",
        'Specifies a COMMA-separated list of days of the week; SU indicates Sunday; MO indicates Monday; TU indicates Tuesday; WE indicates Wednesday; TH indicates Thursday; FR indicates Friday; and SA indicates Saturday.\n\nEach BYDAY value can also be preceded by a positive (+n) or negative (-n) integer. If present, this indicates the nth occurrence of a specific day within the MONTHLY or YEARLY "RRULE". ',
      })
    end
    if not recurrence_field:match "BYMONTHDAY" then
      table.insert(rules, {
        "BYMONTHDAY",
        "Specifies a COMMA-separated list of days of the month. Valid values are 1 to 31 or -31 to -1. For example, -10 represents the tenth to the last day of the month. The BYMONTHDAY rule part **MUST NOT** be specified when the FREQ rule part is set to WEEKLY. ",
      })
    end
    if not recurrence_field:match "BYYEARDAY" then
      table.insert(rules, {
        "BYYEARDAY",
        "Specifies a COMMA-separated list of days of the year. Valid values are 1 to 366 or -366 to -1. For example, -1 represents the last day of the year (December 31st) and -306 represents the 306th to the last day of the year (March 1st). The BYYEARDAY rule part **MUST NOT** be specified when the FREQ rule part is set to DAILY, WEEKLY, or MONTHLY. ",
      })
    end
    if not recurrence_field:match "BYWEEKNO" then
      table.insert(rules, {
        "BYWEEKNO",
        "Specifies a COMMA-separated list of ordinals specifying weeks of the year. Valid values are 1 to 53 or -53 to -1. This corresponds to weeks according to week numbering as defined in [ISO.8601.2004]. A week is defined as a seven day period, starting on the day of the week defined to be the week start (see WKST). Week number one of the calendar year is the first week that contains at least four (4) days in that calendar year. This rule part **MUST NOT** be used when the FREQ rule part is set to anything other than YEARLY. For example, 3 represents the third week of the year. ",
      })
    end
    if not recurrence_field:match "BYMONTH" then
      table.insert(
        rules,
        { "BYMONTH", "Specifies a COMMA-separated list of months of the year.  Valid values are 1 to 12. " }
      )
    end
    if not recurrence_field:match "BYSETPOS" then
      table.insert(rules, {
        "BYSETPOS",
        'Specifies a COMMA-separated list of values that corresponds to the nth occurrence within the set of recurrence instances specified by the rule. BYSETPOS operates on a set of recurrence instances in one interval of the recurrence rule. For example, in a WEEKLY rule, the interval would be one week A set of recurrence instances starts at the beginning of the interval defined by the FREQ rule part. Valid values are 1 to 366 or -366 to -1. It **MUST** only be used in conjunction with another BYxxx rule part. For example "the last work day of the month" could be represented as:\n\nFREQ=MONTHLY;BYDAY=MO,TU,WE,TH,FR;BYSETPOS=-1\n\nEach BYSETPOS value can include a positive (+n) or negative (-n) integer. If present, this indicates the nth occurrence of the specific occurrence within the set of occurrences specified by the rule. ',
      })
    end
    if not recurrence_field:match "WKST" then
      table.insert(rules, {
        "WKST",
        'Specifies the day on which the workweek starts. Valid values are MO, TU, WE, TH, FR, SA, and SU. This is significant when a WEEKLY "RRULE" has an interval greater than 1, and a BYDAY rule part is specified. This is also significant when in a YEARLY "RRULE" when a BYWEEKNO rule part is specified. The default value is MO. ',
      })
    end
    callback {
      items = iter(rules)
        :map(function(rule)
          return {
            label = rule[1],
            documentation = rule[2],
            kind = vim.lsp.protocol.CompletionItemKind.EnumMember,
          }
        end)
        :totable(),
      is_incomplete_backward = false,
      is_incomplete_forward = false,
    }
  elseif (sep_num == 2 or sep_num == 4) and current_propertie == "RRULE" and current_rule then
    local options = {
      FREQ = {
        "SECONDLY",
        "MINUTELY",
        "HOURLY",
        "DAILY",
        "WEEKLY",
        "MONTHLY",
        "YEARLY",
      },
      BYDAY = {
        "SU",
        "MO",
        "TU",
        "WE",
        "TH",
        "FR",
        "SA",
      },
    }
    if not options[current_rule] then
      callback()
      return noop
    end

    callback {
      items = iter(options[current_rule])
        :map(function(option)
          return { label = option, kind = vim.lsp.protocol.CompletionItemKind.EnumMember }
        end)
        :totable(),
      is_incomplete_backward = false,
      is_incomplete_forward = false,
    }
  else
    callback()
    return noop
  end

  return noop
end

function source:execute(ctx, item, callback, default_implementation)
  default_implementation()
  callback()
end

return source
