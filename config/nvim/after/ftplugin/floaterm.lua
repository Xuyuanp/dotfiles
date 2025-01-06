local term = require('floaterm')

vim.keymap.set({ 't' }, '<A-n>', function()
    term.open({ force_new = true })
end, {
    buffer = true,
    noremap = false,
    desc = '[Floaterm] new session',
})

vim.keymap.set({ 't' }, '<A-l>', function()
    term.next_session(true)
end, {
    noremap = false,
    buffer = true,
    desc = '[Floaterm] next session',
})

vim.keymap.set({ 't' }, '<A-h>', function()
    term.prev_session(true)
end, {
    noremap = false,
    buffer = true,
    desc = '[Floaterm] prev session',
})
