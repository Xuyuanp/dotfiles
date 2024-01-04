local M = {}

function M.setup()
    vim.api.nvim_create_user_command('Q', 'execute("qa!")', {})

    vim.api.nvim_create_user_command('Nerdfonts', function()
        require('dotvim.util.nerdfonts').pick()
    end, {})
end

return M
