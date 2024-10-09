if exists("b:current_syntax")
  finish
endif

syn match eventId /^\/[^ ]\+ / conceal

let b:current_syntax = "calendarDay"
