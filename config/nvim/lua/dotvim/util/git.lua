local M = {}

local a = require('dotvim.util.async')
local uv = a.uv()

local icons = {
    BRANCH = '',
    TAG = '',
    COMMIT = '',
}

local choices = {
    {
        icon = icons.BRANCH,
        args = { 'symbolic-ref', '-q', '--short', 'HEAD' },
    },
    {
        icon = icons.TAG,
        args = { 'describe', '--tags', '--exact-match' },
    },
    {
        icon = icons.COMMIT,
        args = { 'rev-parse', '--short', 'HEAD' },
    },
}

M.load_head = a.wrap(function()
    for _, choice in ipairs(choices) do
        local res = uv.simple_job({
            command = 'git',
            args = choice.args,
        }).await()
        if res.code == 0 then
            _G.dotvim_git_head = choice.icon .. ' ' .. res.stdout

            a.schedule().await()
            vim.cmd('redrawstatus')

            return
        end
    end
end)

return M
