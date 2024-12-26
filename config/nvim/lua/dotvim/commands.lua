local M = {}

function M.setup()
    vim.api.nvim_create_user_command('Q', 'execute("qa!")', {})

    vim.api.nvim_create_user_command('Nerdfonts', function()
        require('dotvim.util.nerdfonts').pick()
    end, {})

    vim.api.nvim_create_user_command(
        'DiffOrig',
        'vert new | set buftype=nofile | read ++edit # | 0d_ | diffthis | wincmd p | diffthis',
        { desc = 'see :h DiffOrig' }
    )
end

return M
