(
  (macro_invocation
    macro: ((identifier) @_html_def)
    (token_tree) @rsx)

    (#eq? @_html_def "html")
)

(
 (macro_invocation
  (scoped_identifier
     path: (identifier) @_path
     name: (identifier) @_identifier)

  (token_tree (raw_string_literal) @injection.content))

 (#eq? @_path "sqlx")
 (#match? @_identifier "^query")
 (#offset! @injection.content 0 3 0 -2)
 (#set! injection.language "sql")
)

(
 (macro_invocation
  (scoped_identifier
     path: (identifier) @_path
     name: (identifier) @_identifier)

  (token_tree (string_literal) @injection.content))

 (#eq? @_path "sqlx")
 (#match? @_identifier "^query")
 (#offset! @injection.content 0 1 0 -1)
 (#set! injection.language "sql")
)
