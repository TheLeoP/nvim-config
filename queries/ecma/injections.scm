;; extends

; @Component({
;   template: `<h2>algo</h2>`,
; })

(decorator
  (call_expression
    function: (identifier) @_name
    arguments: (arguments
                 (object
                   (pair
                     key: (property_identifier) @_prop
                     value: (template_string) @injection.content))))
  (#eq? @_name "Component")
  (#eq? @_prop "template")
  (#set! injection.language "html")
  (#offset! @injection.content 0 1 0 -1))


; @Component({
;   styles: [`width: 22;`],
; })

(decorator
  (call_expression
    function: (identifier) @_name
    arguments: (arguments
                 (object
                   (pair
                     key: (property_identifier) @_prop
                     value: (array
                              (template_string) @injection.content)))))
  (#eq? @_name "Component")
  (#eq? @_prop "styles")
  (#set! injection.language "css")
  (#offset! @injection.content 0 1 0 -1))
