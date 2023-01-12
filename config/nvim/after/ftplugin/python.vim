let b:lsp_disable_auto_format = v:true

nnoremap <silent><buffer><leader>R <cmd>echo system(['python', expand('%')])<CR>
