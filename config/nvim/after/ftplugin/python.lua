vim.b.lsp_disable_auto_format = true

vim.keymap.set('n', '<leader>r', function()
    vim.cmd([[echo system(['python', expand('%')])]])
end, { desc = 'source current file', buffer = true })
