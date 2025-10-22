; extends

(jsx_element
  open_tag: (jsx_opening_element)
  .
  _* @tag.inner
  .
  close_tag: (jsx_closing_element)) @tag.outer

(jsx_self_closing_element) @tag.outer

(jsx_self_closing_element
  (jsx_attribute)+ @tag.inner)

(jsx_element
  open_tag: (jsx_opening_element
    name: (_) @tag_name.outer
    _* @tag_name.inner)
  _* @tag_name.inner
  close_tag: (jsx_closing_element
    _* @tag_name.inner
    name: (_) @tag_name.outer))

(jsx_self_closing_element
  name: (_) @tag_name.outer
  (_)* @tag_name.outer @tag_name.inner)
