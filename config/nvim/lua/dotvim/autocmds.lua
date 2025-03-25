local M = {}

function M.setup()
    local group_id = vim.api.nvim_create_augroup('dotvim.init', { clear = true })

    vim.api.nvim_create_autocmd({ 'TextYankPost' }, {
        group = group_id,
        desc = 'Highlight text yanked',
        pattern = { '*' },
        callback = function()
            vim.highlight.on_yank({ timeout = 500 })
        end,
    })

    -- auto save/load cursor position
    vim.api.nvim_create_autocmd('BufReadPost', {
        group = group_id,
        desc = 'restore cursor',
        callback = function()
            if vim.bo.filetype == 'gitcommit' then
                return
            end
            local mark = vim.api.nvim_buf_get_mark(0, '"')
            local lcount = vim.api.nvim_buf_line_count(0)
            if mark[1] > 0 and mark[1] <= lcount then
                pcall(vim.api.nvim_win_set_cursor, 0, mark)
            end
        end,
    })

    vim.api.nvim_create_autocmd({ 'FocusGained', 'TermClose', 'TermLeave' }, {
        group = group_id,
        command = 'checktime',
    })

    vim.api.nvim_create_autocmd('UIEnter', {
        group = group_id,
        desc = 'setup keymaps',
        callback = function()
            require('dotvim.keymaps').setup()
        end,
    })

    vim.api.nvim_create_autocmd('FileType', {
        group = group_id,
        pattern = { 'help', 'man', 'qf' },
        callback = function(args)
            vim.api.nvim_buf_set_keymap(args.buf, 'n', 'q', '<cmd>q<CR>', {
                noremap = true,
                silent = true,
                desc = 'press q to close',
            })
        end,
    })

    local function is_floating(win)
        local config = vim.api.nvim_win_get_config(win or 0)
        return config.relative ~= ''
    end

    vim.api.nvim_create_autocmd('WinEnter', {
        group = group_id,
        desc = 'Auto restore prev window',
        callback = function()
            local prev_winnr = vim.fn.winnr('#')
            local prev_winid = vim.fn.win_getid(prev_winnr)
            local prev_is_floating = is_floating(prev_winid)

            if is_floating() then
                if prev_is_floating then
                    -- jumps from a floating window to another floating window
                    return
                end
                -- mark the previous window to restore its previous window
                vim.w[prev_winid].restore_prev_window = true
                return
            end

            -- enter a normal window
            if vim.w.restore_prev_window and vim.w.prev_window then
                vim.w.restore_prev_window = nil
                local winid = vim.fn.win_getid(vim.w.prev_winnr)
                if not vim.api.nvim_win_is_valid(winid) then
                    return
                end
                local winnr = vim.fn.winnr()
                vim.cmd('noautocmd ' .. vim.w.prev_window .. 'wincmd w')
                vim.cmd('noautocmd ' .. winnr .. 'wincmd w')
                return
            end

            vim.w.prev_window = (not prev_is_floating) and prev_winnr or nil
        end,
    })
end

return M
