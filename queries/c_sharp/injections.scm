;;extends

; new NpgsqlCommand("");
(object_creation_expression
  type: (identifier) @class
  arguments: (argument_list
               (argument
                 (string_literal
                   (string_literal_content) @injection.content)))
  (#any-of? @class "NpgsqlCommand")
  (#set! injection.language "sql"))

; new NpgsqlCommand($"");
; new NpgsqlCommand(@$"");
(object_creation_expression
  type: (identifier) @class
  arguments: (argument_list
               (argument
                 (interpolated_string_expression
                   (string_content) @injection.content)))
  (#any-of? @class "NpgsqlCommand")
  (#set! injection.language "sql")
  (#set! injection.combined))

; new NpgsqlCommand(@"");
(object_creation_expression
  type: (identifier) @class
  arguments: (argument_list
               (argument
                 (verbatim_string_literal) @injection.content))
  (#any-of? @class "NpgsqlCommand")
  (#offset! @injection.content 0 2 0 -1)
  (#set! injection.language "sql"))

; new NpgsqlCommand("""""");
(object_creation_expression
  type: (identifier) @class
  arguments: (argument_list
               (argument
                 (raw_string_literal
                   (raw_string_content) @injection.content)))
  (#any-of? @class "NpgsqlCommand")
  (#set! injection.language "sql"))
