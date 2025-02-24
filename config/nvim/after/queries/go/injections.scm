;; extends

(
 [
  ; const foo = /* lang */ "..."
  ; const foo = /* lang */ `...`
  (
   const_spec
   (comment) @_comment.lang .
   value: (expression_list
            [
             (interpreted_string_literal (interpreted_string_literal_content) @injection.content)
             (raw_string_literal (raw_string_literal_content) @injection.content)
             ]
            )
   )
  ; foo := /* lang */ "..."
  ; foo := /* lang */ `...`
  (
   short_var_declaration
   (comment) @_comment.lang .
   right: (expression_list
            [
             (interpreted_string_literal (interpreted_string_literal_content) @injection.content)
             (raw_string_literal (raw_string_literal_content) @injection.content)
             ]
            )
   )
  ; var foo = /* lang */ "..."
  ; var foo = /* lang */ `...`
  (
   var_spec
   (comment) @_comment.lang .
   value: (expression_list
            [
             (interpreted_string_literal (interpreted_string_literal_content) @injection.content)
             (raw_string_literal (raw_string_literal_content) @injection.content)
             ]
            )
   )
  ; fn(/*lang*/ "...")
  ; fn(/*lang*/ `...`)
  (
   argument_list
   (comment) @_comment.lang .
   [
    (interpreted_string_literal (interpreted_string_literal_content) @injection.content)
    (raw_string_literal (raw_string_literal_content) @injection.content)
    ]
   )
  ; []byte(/*lang*/ "...")
  ; []byte(/*lang*/ `...`)
  (
   type_conversion_expression
   (comment) @_comment.lang .
   operand:  [
              (interpreted_string_literal (interpreted_string_literal_content) @injection.content)
              (raw_string_literal (raw_string_literal_content) @injection.content)
              ]
   )
  ; []Type{ /*lang*/ "..." }
  ; []Type{ /*lang*/ `...` }
  (
   literal_value
   (comment) @_comment.lang .
   (literal_element
     [
      (interpreted_string_literal (interpreted_string_literal_content) @injection.content)
      (raw_string_literal (raw_string_literal_content) @injection.content)
      ]
     )
   )
  ; map[Type]Type{ key: /*lang*/ "..." }
  ; map[Type]Type{ key: /*lang*/ `...` }
  (
   keyed_element
   (comment) @_comment.lang .
   value: (literal_element
            [
             (interpreted_string_literal (interpreted_string_literal_content) @injection.content)
             (raw_string_literal (raw_string_literal_content) @injection.content)
             ]
            )
   )
  ]
 (#gsub! @_comment.lang "/%*%s*([%w%p]+)%s*%*/" "%1")
 (#inject-lang-ref! @_comment.lang)
 )
