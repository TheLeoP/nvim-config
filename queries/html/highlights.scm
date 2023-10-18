;extends

((attribute_name) @keyword
                  (#lua-match? @keyword "^%*ng")
                  (#offset! @keyword 0 1 0 0))

((attribute_name) @keyword
                  (#lua-match? @keyword "^%[[^()]*%]$")
                  (#offset! @keyword 0 1 0 -1))

((attribute_name) @keyword
                  (#lua-match? @keyword "^%[%(.*%)%]$")
                  (#offset! @keyword 0 2 0 -2))

((attribute_name) @keyword
                  (#lua-match? @keyword "^%(.*%)$")
                  (#offset! @keyword 0 1 0 -1))
