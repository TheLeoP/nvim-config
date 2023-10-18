; extends

; *ngFor="let product of products"

(_
  (attribute_name) @attr
  (quoted_attribute_value
    (attribute_value)@injection.content)
  (#lua-match? @attr "^%*ng")
  (#set! injection.language "angular"))

; [title]="product.name + ' details'"

(attribute
 (attribute_name) @attr
 (quoted_attribute_value
   (attribute_value)@injection.content)
 (#lua-match? @attr "^%[[^()]*%]$")
 (#set! injection.language "angular"))

; [(title)]="product.name + ' details'"

(attribute
 (attribute_name) @attr
 (quoted_attribute_value
   (attribute_value)@injection.content)
 (#lua-match? @attr "^%[%(.*%)%]$")
 (#set! injection.language "angular"))

; (click)="share"

(attribute
 (attribute_name) @attr
 (quoted_attribute_value
   (attribute_value)@injection.content)
 (#lua-match? @attr "^%(.*%)$")
 (#set! injection.language "angular"))


; <div>{{product.name}}</div>

((text) @injection.content
        (#lua-match? @injection.content "{{.*}}")
        (#offset-lua-match! @injection.content "{{.*}}" 0 2 0 -2)
        (#set! injection.language "angular"))

; routerLink="{{product.id}}"

((attribute_value) @injection.content
                   (#lua-match? @injection.content "^{{.*}}$")
                   (#offset! @injection.content 0 2 0 -2)
                   (#set! injection.language "angular"))
