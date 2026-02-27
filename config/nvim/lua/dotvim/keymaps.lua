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
    set_keymap('v', '<leader>y', '"+y', { desc = 'Yank selection to system clipboard' })
    set_keymap('n', '<leader>Y', '"+yy', { desc = 'Yank line to system clipboard' })
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
            local diag = vim.diagnostic.jump({
                count = direction,
                severity = severity,
            })
            if not diag then
                return
            end

            vim.diagnostic.show(diag.namespace, diag.bufnr, { diag }, { virtual_lines = { current_line = true } })
        end
    end

    local F, B = 1, -1
    local E, W = vim.diagnostic.severity.ERROR, vim.diagnostic.severity.WARN
    set_keymap('n', ']d', diagnostic_jump(F), { desc = '[Diagnostic] jump to next diagnostic' })
    set_keymap('n', '[d', diagnostic_jump(B), { desc = '[Diagnostic] jump to prev diagnostic' })
    set_keymap('n', ']e', diagnostic_jump(F, E), { desc = '[Diagnostic] jump to next error' })
    set_keymap('n', '[e', diagnostic_jump(B, E), { desc = '[Diagnostic] jump to prev error' })
    set_keymap('n', ']w', diagnostic_jump(F, W), { desc = '[Diagnostic] jump to next warning' })
    set_keymap('n', '[w', diagnostic_jump(B, W), { desc = '[Diagnostic] jump to prev warning' })
    ---]]

    ---[[ snippets support
    local snippets_switch = function(direction, fallback)
        return function()
            if vim.snippet.active({ direction = direction }) then
                vim.snippet.jump(direction)
            else
                vim.api.nvim_feedkeys(vim.keycode(fallback), 'n', false)
            end
        end
    end
    set_keymap('i', '<C-j>', snippets_switch(F, '<C-j>'), { desc = '[Snippets] jump forward' })
    set_keymap('i', '<C-k>', snippets_switch(B, '<C-k>'), { desc = '[Snippets] jump backward' })
    ---]]

    set_keymap('n', '<leader>gl', function()
        require('dotvim.util.git').remote_link()
    end, { desc = '[Git] Remote Link' })

    local hover_timer = vim.uv.new_timer()
    assert(hover_timer, 'Failed to create hover timer')
    local on_hover = function()
        local mouse_pos = vim.fn.getmousepos()
        local winid = mouse_pos.winid
        if winid == 0 then
            return
        end
        local bufnr = vim.api.nvim_win_get_buf(winid)

        vim.api.nvim_exec_autocmds({ 'User' }, {
            pattern = 'MouseHover',
            data = {
                win = winid,
                buf = bufnr,
                mouse_pos = mouse_pos,
            },
        })
    end
    set_keymap({ 'i', 'n' }, '<MouseMove>', function()
        hover_timer:start(800, 0, function()
            hover_timer:stop()
            vim.schedule(on_hover)
        end)
    end, {
        noremap = true,
        silent = true,
        desc = 'Mouse move (no-op, for hover autocmd)',
    })
end

return {
    setup = setup,
}
