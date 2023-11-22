local M = {}

function M.setup()
    vim.api.nvim_create_user_command('Q', 'execute("qa!")', {})
end

return M
