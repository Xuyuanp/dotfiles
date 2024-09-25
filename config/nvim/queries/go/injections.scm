; extends

; stolen from https://github.com/ray-x/go.nvim/blob/master/after/queries/go/injections.scm

((const_spec
  name: (identifier) @_const
  value: (expression_list (raw_string_literal) @json))
 (#lua-match? @_const ".*[J|j]son.*"))

((short_var_declaration
    left: (expression_list
            (identifier) @_var)
    right: (expression_list
             (raw_string_literal) @json))
  (#lua-match? @_var ".*[J|j]son.*")
  (#offset! @json 0 1 0 -1))

(const_spec
  name: (identifier)
  value: (expression_list (raw_string_literal) @injection.content
   (#lua-match? @injection.content "^`[\n|\t| ]*\{.*\}[\n|\t| ]*`$")
   (#offset! @injection.content 0 1 0 -1)
   (#set! injection.language "json")))

(short_var_declaration
    left: (expression_list (identifier))
    right: (expression_list (raw_string_literal) @injection.content)
  (#lua-match? @injection.content "^`[\n|\t| ]*\{.*\}[\n|\t| ]*`$")
  (#offset! @injection.content 0 1 0 -1)
  (#set! injection.language "json"))

(var_spec
  name: (identifier)
  value: (expression_list (raw_string_literal) @injection.content
   (#lua-match? @injection.content "^`[\n|\t| ]*\{.*\}[\n|\t| ]*`$")
   (#offset! @injection.content 0 1 0 -1)
   (#set! injection.language "json")))
