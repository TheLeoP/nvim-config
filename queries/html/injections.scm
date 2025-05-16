;extends

((attribute_name) @_name
  (quoted_attribute_value
    (attribute_value) @injection.content)
  (#eq? @_name "onClick")
  (#set! injection.language "javascript"))

(style_element
  (raw_text) @injection.content
  (#set! injection.language "css"))
