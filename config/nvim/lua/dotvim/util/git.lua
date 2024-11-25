local M = {}

local a = require('dotvim.util.async')

local icons = {
    BRANCH = '',
    TAG = '',
    COMMIT = '',
}

local choices = {
    {
        icon = icons.BRANCH,
        args = { 'git', 'symbolic-ref', '-q', '--short', 'HEAD' },
    },
    {
        icon = icons.TAG,
        args = { 'git', 'describe', '--tags', '--exact-match' },
    },
    {
        icon = icons.COMMIT,
        args = { 'git', 'rev-parse', '--short', 'HEAD' },
    },
}

local load_head = a.wrap(function(tab)
    for _, choice in ipairs(choices) do
        local res = a.system(choice.args, { text = true }).await()
        if res.code == 0 then
            vim.t[tab].dotvim_git_head = choice.icon .. ' ' .. vim.trim(res.stdout)
            _G.dotvim_git_head = choice.icon .. ' ' .. vim.trim(res.stdout)

            a.schedule().await()
            vim.cmd('redrawstatus')

            return
        end
    end
end)

function M.load_head()
    local tab = vim.api.nvim_get_current_tabpage()
    load_head(tab)
end

return M
