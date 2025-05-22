; extends

; copied from nvim-treesitter-textobjects
(element) @tag.outer

(element
  (start_tag)
  .
  (_) @tag.inner
  .
  (end_tag))

(element
  (start_tag)
  _+ @tag.inner
  (end_tag))

(script_element) @tag.outer

(script_element
  (start_tag)
  .
  (_) @tag.inner
  .
  (end_tag))

(style_element) @tag.outer

(style_element
  (start_tag)
  .
  (_) @tag.inner
  .
  (end_tag))

; custom
(self_closing_tag
  ((attribute)+) @tag.inner)
