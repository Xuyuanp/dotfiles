local a = require('dotvim.util.async')

local M = {}

M.pick = a.wrap(function()
    local uv = a.uv()

    if not M.nerdfonts then
        local path = vim.fn.stdpath('config') .. '/misc/nerdfonts.txt'
        local err, data = uv.read_file(path)
        assert(not err, err)
        if not data then
            vim.notify('nerdfonts.txt is empty', vim.log.levels.WARN)
            return
        end

        M.nerdfonts = vim.split(data, '\n', { plain = true })
    end

    a.schedule().await()

    local item = a.ui
        .select(M.nerdfonts, {
            prompt = 'Pick icon',
        })
        .await()

    if not item then
        return
    end

    local fields = vim.split(item, '%s+', { plain = false })
    local ICON = 2
    local icon = fields[ICON]
    vim.fn.setreg(vim.v.register, icon)
    vim.notify(string.format('icon %s is copied', icon), vim.log.levels.INFO, { title = 'Nerdfonts' })
end)

return M
