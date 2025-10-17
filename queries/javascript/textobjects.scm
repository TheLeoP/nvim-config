; extends

(jsx_element) @tag.outer

(jsx_self_closing_element) @tag.outer

(jsx_element
  (jsx_opening_element)
  .
  (_) @tag.inner
  .
  (jsx_closing_element))

(jsx_element
  (jsx_opening_element)
  _+ @tag.inner
  (jsx_closing_element))

(jsx_self_closing_element
  ((jsx_attribute)+) @tag.inner)
