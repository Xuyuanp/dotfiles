local a = require('dotvim.util.async')

local M = {}

M.pick = a.wrap(function()
    local uv = a.uv()

    if not M.nerdfonts then
        local path = vim.fn.stdpath('config') .. '/misc/nerdfonts.txt'
        local err, data = uv.read_file(path)
        assert(not err, err)

        M.nerdfonts = vim.split(data, '\n')
    end

    a.schedule().await()

    local item = a.ui.select(M.nerdfonts, {
        prompt = 'Pick icon',
    }).await()

    if not item then
        return
    end

    local fields = vim.split(item, ' ')
    local ICON = 2
    vim.fn.setreg(vim.v.register, fields[ICON])
end)

return M
