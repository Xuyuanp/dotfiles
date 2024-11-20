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

    set_keymap('n', 'j', 'gj', opts)
    set_keymap('n', 'k', 'gk', opts)

    ---[[ snippets support
    local snippets_switch = function(direction, fallback)
        return function()
            return vim.snippet.active({ direction = direction }) and vim.snippet.jump(direction) or fallback
        end
    end
    set_keymap('i', '<C-j>', snippets_switch(1, '<C-j>'), { desc = '[Snippets] jump forward' })
    set_keymap('i', '<C-k>', snippets_switch(-1, '<C-k>'), { desc = '[Snippets] jump backward' })
    ---]]
end

return {
    setup = setup,
}
