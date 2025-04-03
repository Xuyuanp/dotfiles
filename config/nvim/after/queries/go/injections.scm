;; extends

(
 [
  ; const foo = /* lang:name */ "..."
  ; const foo = /* lang:name */ `...`
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
  ; foo := /* lang:name */ "..."
  ; foo := /* lang:name */ `...`
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
  ; var foo = /* lang:name */ "..."
  ; var foo = /* lang:name */ `...`
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
  ; fn(/* lang:name */ "...")
  ; fn(/* lang:name */ `...`)
  (
   argument_list
   (comment) @_comment.lang .
   [
    (interpreted_string_literal (interpreted_string_literal_content) @injection.content)
    (raw_string_literal (raw_string_literal_content) @injection.content)
    ]
   )
  ; []byte(/* lang:name */ "...")
  ; []byte(/* lang:name */ `...`)
  (
   type_conversion_expression
   (comment) @_comment.lang .
   operand:  [
              (interpreted_string_literal (interpreted_string_literal_content) @injection.content)
              (raw_string_literal (raw_string_literal_content) @injection.content)
              ]
   )
  ; []Type{ /* lang:name */ "..." }
  ; []Type{ /* lang:name */ `...` }
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
  ; map[Type]Type{ key: /* lang:name */ "..." }
  ; map[Type]Type{ key: /* lang:name */ `...` }
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

(
 (call_expression
   function: (selector_expression
               field: (field_identifier) @_method)
   arguments: (argument_list
                .
                (interpreted_string_literal
                  (interpreted_string_literal_content) @injection.content)))
 (#any-of? @_method "Tracef" "Debugf" "Infof" "Warnf" "Warningf" "Errorf")
 (#set! injection.language "printf")
 )
