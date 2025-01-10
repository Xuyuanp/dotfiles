if vim.b.did_indent then
    return
end
vim.b.did_indent = true

vim.bo.cindent = true
vim.bo.expandtab = true
vim.bo.shiftwidth = 2

vim.b.undo_indent = 'setlocal cin<'
