local function setup()
    local set_keymap = vim.keymap.set
    local opts = {}

    ---[[ Navigation between split windows
    set_keymap('n', '<C-j>', '<C-w>j', opts)
    set_keymap('n', '<C-k>', '<C-w>k', opts)
    set_keymap('n', '<C-h>', '<C-w>h', opts)
    set_keymap('n', '<C-l>', '<C-w>l', opts)

    set_keymap('n', '<Up>', '<C-w>+', opts)
    set_keymap('n', '<Down>', '<C-w>-', opts)
    set_keymap('n', '<Left>', '<C-w><', opts)
    set_keymap('n', '<Right>', '<C-w>>', opts)
    ---]]

    ---[[ Reselect visual block after indent/outdent
    set_keymap('v', '<', '<gv', opts)
    set_keymap('v', '>', '>gv', opts)
    ---]]

    ---[[ Clear search highlight
    set_keymap('n', '<leader>/', '<cmd>nohls<CR>', opts)
    ---]]

    ---[[ Keep search pattern at the center of the screen
    set_keymap('n', 'n', 'nzz', opts)
    set_keymap('n', 'N', 'Nzz', opts)
    set_keymap('n', '*', '*zz', opts)
    set_keymap('n', '#', '#zz', opts)
    set_keymap('n', 'g*', 'g*zz', opts)
    ---]]

    ---[[ Mimic emacs line editing in insert mode only
    set_keymap('i', '<C-a>', '<Home>', opts)
    set_keymap('i', '<C-b>', '<Left>', opts)
    set_keymap('i', '<C-e>', '<End>', opts)
    set_keymap('i', '<C-f>', '<Right>', opts)
    ---]]

    ---[[ Yank to system clipboard
    set_keymap('v', '<leader>y', '"+y', opts)
    set_keymap('n', '<leader>yy', '"+yy', opts)

    set_keymap('n', '<leader>p', '"+p', opts)
    ---]]

    ---[[ Diagnostics
    set_keymap('n', ']d', vim.diagnostic.goto_next, opts)
    set_keymap('n', '[d', vim.diagnostic.goto_prev, opts)
    set_keymap('n', '<leader>sd', vim.diagnostic.open_float, opts)
    ---]]

    set_keymap('n', 'j', 'gj', opts)
    set_keymap('n', 'k', 'gk', opts)

    ---[[ snippets support
    set_keymap('i', '<C-j>', function()
        return vim.snippet.active({ direction = 1 }) and vim.snippet.jump(1) or '<C-j>'
    end, { desc = '[Snippets] jump forward' })
    set_keymap('i', '<C-k>', function()
        return vim.snippet.active({ direction = -1 }) and vim.snippet.jump(-1) or '<C-k>'
    end, { desc = '[Snippets] jump backward' })
    ---]]
end

return {
    setup = setup,
}
