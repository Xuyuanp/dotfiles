local M = {}
function M.hunk_text_object()
    local node = vim.treesitter.get_node()
    while node do
        if node:type() == 'hunk' then
            break
        end
        node = node:parent()
    end

    if not node then
        vim.notify('hunk not found', vim.log.levels.WARN)
        return
    end
    local start_row, _, end_row = node:range()
    local end_line = vim.api.nvim_buf_get_lines(0, end_row - 1, end_row, true)[1]
    local end_col = string.len(end_line)

    -- Select the range
    vim.fn.setpos("'<", { 0, start_row + 1, 0, 0 })
    vim.fn.setpos("'>", { 0, end_row, end_col, 0 })
    vim.cmd('normal! gv')
end

vim.keymap.set({ 'x', 'o' }, 'ih', M.hunk_text_object, { buffer = true, desc = 'inner hunk' })
vim.keymap.set('n', '<leader>D', 'vihD', { buffer = true, desc = '[Diff] delete current hunk', remap = true })

vim.wo.foldmethod = 'expr'
vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
