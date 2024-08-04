if exists("b:current_syntax") | finish | endif

syn match kinesisComment /^\*.*$/
syn match kinesisSymbol />/
syn region kinesisMacro transparent matchgroup=kinesisParensMacro start=/{/ end=/}/ contains=kinesisModifier,kinesisKey
syn region kinesisRemap transparent matchgroup=kinesisParensRemap start=/\[/ end=/]/ contains=kinesisModifier,kinesisKey

syn iskeyword @,48-57,192-255,&,.,=,‘,;,\,/,`,'
syn keyword kinesisModifier lalt lctrl lshift ralt rctrl rshift rwin lwin contained
syn match kinesisPlusMinus /[+-]/
syn match kinesisModifier /[+-]\(lalt\|lctrl\|lshift\|lwin\|ralt\|rctrl\|rshift\|rwin\)/ contained contains=kinesisPlusMinus
syn match kinesisModifier /t&h\d\+/he=s+3 contains=kinesisNumber

syn keyword kinesisKey contained f1 f2 f3 f4 f5 f6 f7 f8 f9 f10 f11 f12 f13 f14 f15 f16 f17 f18 f19 f20 f21 f22 f23 f24 1 2 3 4 5 6 7 8 9 0 hyphen = a b c d e f g h i j k l m n o p q r s t u v w x y z obrack cbrack meh hyper next prev play mute vol+ calc enter tab space delete bspace escape prtscr scroll caps insert pause menu kptoggle kpshift numlk kp0 kp1 kp3 kp3 kp4 kp5 kp6 kp7 kp8 kp9 kp. kpdiv kpplus kpmin kpmult kpenter1 kp=mac shutdn lmouse rmouse mmouse left down right up pup pdown null home end
syn match kinesisKey contained /[`;\\/']/
syn match kinesisKey contained /intl-\\/

syn match kinesisNumber /\d/

hi link kinesisComment @comment
hi link kinesisSymbol None
hi link kinesisParensMacro Macro
hi link kinesisParensRemap Special
hi link kinesisModifier Keyword
hi link kinesisKey Identifier
hi link kinesisNumber Number
hi link kinesisPlusMinus Character

let b:current_syntax = "kinesis"
