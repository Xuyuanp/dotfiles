local M = {}

function M.get_name(bufnr)
    local clients = vim.lsp.get_clients({
        bufnr = bufnr,
    })
    if not clients or #clients == 0 then
        return ''
    end
    local _, client = next(clients)
    return client.name
end

return M
