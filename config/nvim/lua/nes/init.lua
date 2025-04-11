local M = {}

function M.setup(opts)
    opts = opts or {}

    vim.lsp.enable('nes', true)
end

return M
