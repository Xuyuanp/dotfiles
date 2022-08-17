if exists("b:did_indent")
   finish
endif
let b:did_indent = 1

" Protobuf is like indenting C
setlocal cindent
setlocal expandtab
setlocal shiftwidth=2

let b:undo_indent = "setl cin<"
