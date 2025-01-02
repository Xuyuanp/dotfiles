vim.keymap.set({ 't' }, '<A-n>', function()
    Floaterm:open({ force_new = true })
end, {
    buffer = true,
    noremap = false,
    desc = '[Floaterm] new session',
})

vim.keymap.set({ 't' }, '<A-l>', function()
    Floaterm:next_session(true)
end, {
    noremap = false,
    buffer = true,
    desc = '[Floaterm] next session',
})

vim.keymap.set({ 't' }, '<A-h>', function()
    Floaterm:prev_session(true)
end, {
    noremap = false,
    buffer = true,
    desc = '[Floaterm] prev session',
})
