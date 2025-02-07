;; extends

((raw_string_literal_content)
  @injection.content
  (#lua-match? @injection.content "^%s*\{.*\}%s*$")
  (#set! injection.language "json")
  )

((raw_string_literal_content)
  @injection.content
  (#lua-match? @injection.content "^%s*(SELECT|UPDATE|DELETE|ALTER)%s")
  (#set! injection.language "sql")
  )
