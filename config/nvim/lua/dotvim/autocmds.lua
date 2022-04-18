local group_id = vim.api.nvim_create_augroup('dotvim_init', { clear = true })

local M = {}

function M.setup()
    vim.api.nvim_create_autocmd({ 'CursorHold' }, {
        group = group_id,
        desc = 'show git lens',
        pattern = { '*' },
        callback = function()
            require('dotvim.git.lens').show()
        end,
    })

    vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        group = group_id,
        desc = 'clear git lens',
        pattern = { '*' },
        callback = function()
            require('dotvim.git.lens').clear()
        end,
    })

    vim.api.nvim_create_autocmd({ 'DirChanged' }, {
        group = group_id,
        desc = 'refresh git head',
        pattern = { '*' },
        callback = function()
            require('dotvim.git.head').lazy_load()
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

    vim.api.nvim_create_autocmd({ 'User' }, {
        group = group_id,
        desc = 'Compile automatically after packer complete',
        pattern = { 'PackerComplete' },
        command = 'PackerCompile',
    })
end

return M
