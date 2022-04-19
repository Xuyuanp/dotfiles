local a = require('dotvim.util.async')

local M = {}

function M.setup()
    local ts = require('telescope')
    ts.setup({
        defaults = {
            vimgrep_arguments = {
                'rg',
                '--color=never',
                '--no-heading',
                '--with-filename',
                '--line-number',
                '--column',
                '--smart-case',
            },
            prompt_prefix = '  ',
        },
    })
end

M.nerdfonts = a.wrap(function()
    local uv = a.uv()

    local path = vim.fn.stdpath('config') .. '/lua/dotvim/util/nerdfonts.txt'
    local err, data = uv.read_file(path)
    assert(not err, err)

    local items = vim.split(data, '\n')

    a.schedule().await()

    local item = a.ui.select(items, {
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
