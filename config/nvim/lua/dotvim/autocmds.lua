local group_id = vim.api.nvim_create_augroup('dotvim_init', { clear = true })

local M = {}

function M.setup()
    vim.api.nvim_create_autocmd({ 'DirChanged' }, {
        group = group_id,
        desc = 'refresh git head',
        pattern = { '*' },
        callback = function()
            require('dotvim.util.git').load_head()
        end,
    })

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
        callback = function()
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

    vim.api.nvim_create_autocmd('FileType', {
        group = group_id,
        desc = 'Disable features in big files',
        pattern = 'bigfile',
        callback = vim.schedule_wrap(function(args)
            vim.bo[args.buf].syntax = vim.filetype.match({ buf = args.buf }) or ''
        end),
    })
end

return M
