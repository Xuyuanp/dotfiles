local Term = require('dotvim.lib.floaterm')

local term = Term.new()

vim.keymap.set({ 'n', 't' }, '<A-t>', function()
    term:toggle()
end, {
    noremap = false,
    silent = true,
    desc = '[Floaterm] toggle',
})

vim.keymap.set({ 't' }, '<A-n>', function()
    if not vim.b.floaterm then
        return
    end
    term:open({ force_new = true })
end, {
    noremap = false,
    remap = true,
    desc = '[Floaterm] new session',
})

vim.keymap.set({ 't' }, '<A-l>', function()
    if not vim.b.floaterm then
        return
    end
    term:next_session(true)
end, {
    noremap = false,
    remap = true,
    desc = '[Floaterm] next session',
})

vim.keymap.set({ 't' }, '<A-h>', function()
    if not vim.b.floaterm then
        return
    end
    term:prev_session(true)
end, {
    noremap = false,
    remap = true,
    desc = '[Floaterm] prev session',
})

local group_id = vim.api.nvim_create_augroup('dotvim_floaterm', { clear = true })
vim.api.nvim_create_autocmd('WinResized', {
    group = group_id,
    callback = function()
        term:update()
    end,
})
