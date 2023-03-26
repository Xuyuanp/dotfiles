local M = {}

function M.setup(opts)
    opts = opts or {}
end

function M.toggle()
    if not M.chat then
        M.chat = require('neochat.chat').new()
        return
    end

    M.chat:toggle()
end

return M
