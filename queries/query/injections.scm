;extends

((predicate
  name: (identifier) @_name
  parameters: (parameters (string) @injection.content))
 (#eq? @_name "offset-lua-match")
 (#set! injection.language "luap")
 (#offset! @injection.content 0 1 0 -1))
