; extends

(function_call
  name: (dot_index_expression
    table: (identifier) @_table
    field: (identifier) @_field)
  arguments: (arguments
    (string
      content: (string_content) @injection.content))
  (#eq? @_table child)
  (#eq? @_field lua)
  (#set! injection.language "lua"))
