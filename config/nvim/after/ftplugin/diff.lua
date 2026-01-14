local M = {}
function M.hunk_text_object()
    local node = vim.treesitter.get_node()
    while node and node:type() ~= 'hunk' do
        node = node:parent()
    end

    if not node then
        vim.notify('hunk not found', vim.log.levels.WARN)
        return
    end
    local start_row = node:start() + 1
    local start_col = 0
    local end_row = node:end_()
    local end_col = string.len(vim.fn.getline(end_row))

    -- Select the range
    vim.fn.setpos("'<", { 0, start_row, start_col, 0 })
    vim.fn.setpos("'>", { 0, end_row, end_col, 0 })
    vim.cmd('normal! gv')
end

vim.keymap.set({ 'x', 'o' }, 'ih', M.hunk_text_object, { buffer = true, desc = 'inner hunk' })
vim.keymap.set('n', '<leader>D', 'vihD', { buffer = true, desc = '[Diff] delete current hunk', remap = true })

-- foldmethod would be updated by plugin ufo, so we need to set it again
local winnr = vim.api.nvim_get_current_win()
vim.defer_fn(function()
    if not vim.api.nvim_win_is_valid(winnr) then
        return
    end
    vim.wo[winnr].foldmethod = 'expr'
end, 500)
