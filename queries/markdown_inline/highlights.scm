;extends

((backslash_escape) @conceal
  (#eq? @conceal "\\.")
  (#set! conceal "."))
