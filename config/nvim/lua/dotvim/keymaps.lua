local function setup()
    local set_keymap = vim.keymap.set
    local opts = {}

    ---[[ Navigation between split windows
    set_keymap('n', '<C-j>', '<C-w>j', opts)
    set_keymap('n', '<C-k>', '<C-w>k', opts)
    set_keymap('n', '<C-h>', '<C-w>h', opts)
    set_keymap('n', '<C-l>', '<C-w>l', opts)
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
    ---]]

    ---[[
    set_keymap('n', 'j', 'gj', opts)
    set_keymap('n', 'k', 'gk', opts)
    ---]]

    ---[[ Move Lines
    set_keymap('n', '<A-j>', "<CMD>execute 'move .+' . v:count1<CR>==", { desc = 'Move Down' })
    set_keymap('n', '<A-k>', "<CMD>execute 'move .-' . (v:count1 + 1)<CR>==", { desc = 'Move Up' })
    set_keymap('i', '<A-j>', '<ESC><CMD>m .+1<CR>==gi', { desc = 'Move Down' })
    set_keymap('i', '<A-k>', '<ESC><CMD>m .-2<CR>==gi', { desc = 'Move Up' })
    set_keymap('v', '<A-j>', ":<C-u>execute \"'<,'>move '>+\" . v:count1<CR>gv=gv", { desc = 'Move Down' })
    set_keymap('v', '<A-k>', ":<C-u>execute \"'<,'>move '<-\" . (v:count1 + 1)<CR>gv=gv", { desc = 'Move Up' })
    ---]]

    ---[[
    set_keymap('n', '<leader>s', '<cmd>w<CR>', { desc = 'Save' })
    ---]]

    ---[[ diagnostic navigation
    local function diagnostic_jump(direction, severity)
        return function()
            vim.diagnostic.jump({
                count = direction,
                severity = severity,
            })
        end
    end

    local F, B = 1, -1
    local E, W = vim.diagnostic.severity.ERROR, vim.diagnostic.severity.WARN
    set_keymap('n', ']e', diagnostic_jump(F, E), { desc = '[Diagnostic] jump to next error' })
    set_keymap('n', '[e', diagnostic_jump(B, E), { desc = '[Diagnostic] jump to prev error' })
    set_keymap('n', ']w', diagnostic_jump(F, W), { desc = '[Diagnostic] jump to next warning' })
    set_keymap('n', '[w', diagnostic_jump(B, W), { desc = '[Diagnostic] jump to prev warning' })
    ---]]

    ---[[ snippets support
    local snippets_switch = function(direction, fallback)
        return function()
            return vim.snippet.active({ direction = direction }) and vim.snippet.jump(direction) or fallback
        end
    end
    set_keymap('i', '<C-j>', snippets_switch(F, '<C-j>'), { desc = '[Snippets] jump forward' })
    set_keymap('i', '<C-k>', snippets_switch(B, '<C-k>'), { desc = '[Snippets] jump backward' })
    ---]]
end

return {
    setup = setup,
}
