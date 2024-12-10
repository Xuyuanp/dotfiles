;; inherits: haskell
;; extends

((operator) @conceal (#eq? @conceal ">>=") (#set! conceal ""))
((operator) @conceal (#eq? @conceal "<*>") (#set! conceal "⊛"))
((operator) @conceal (#eq? @conceal "<$>") (#set! conceal "ⓜ"))
((operator) @conceal (#eq? @conceal "\\") (#set! conceal "λ")) ; not work

((variable) @conceal (#eq? @conceal "div") (#set! conceal "÷"))
((variable) @conceal (#eq? @conceal "not") (#set! conceal "¬"))
((variable) @conceal (#eq? @conceal "mappend") (#set! conceal "󰐙"))
((variable) @conceal (#eq? @conceal "sqrt") (#set! conceal "√"))
((variable) @conceal (#eq? @conceal "sum") (#set! conceal "∑"))
((variable) @conceal (#eq? @conceal "product") (#set! conceal "∏"))
((variable) @conceal (#eq? @conceal "undefined") (#set! conceal "⊥"))

((variable) @conceal (#eq? @conceal "elem") (#set! conceal "∈"))
((variable) @conceal (#eq? @conceal "notElem") (#set! conceal "∉"))
((variable) @conceal (#eq? @conceal "isSubsetOf") (#set! conceal "⊆"))
((variable) @conceal (#eq? @conceal "union") (#set! conceal "∪"))
((variable) @conceal (#eq? @conceal "intersect") (#set! conceal "∩"))

((type) @conceal (#eq? @conceal "Maybe") (#set! conceal "𝐌"))
((constructor) @conceal (#eq? @conceal "Just") (#set! conceal "𝐽"))
((constructor) @conceal (#eq? @conceal "Nothing") (#set! conceal "𝑁"))

((type) @conceal (#eq? @conceal "String") (#set! conceal "𝐒"))

((type) @conceal (#eq? @conceal "Either") (#set! conceal "𝐄"))
((constructor) @conceal (#eq? @conceal "Left") (#set! conceal "𝐿"))
((constructor) @conceal (#eq? @conceal "Right") (#set! conceal "𝑅"))

((type) @conceal (#eq? @conceal "Bool") (#set! conceal "𝔹"))
((constructor) @conceal (#eq? @conceal "True") (#set! conceal "𝐓"))
((constructor) @conceal (#eq? @conceal "False") (#set! conceal "𝐅"))
