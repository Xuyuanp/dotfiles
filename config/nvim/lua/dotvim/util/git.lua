local M = {}

local a = require('dotvim.util.async')
local icons = require('dotvim.settings').icons.git

local choices = {
    {
        icon = icons.branch,
        args = { 'symbolic-ref', '-q', '--short', 'HEAD' },
    },
    {
        icon = icons.tag,
        args = { 'describe', '--tags', '--exact-match' },
    },
    {
        icon = icons.commit,
        args = { 'rev-parse', '--short', 'HEAD' },
    },
}

---@param bufnr number
---@param root? string
local load_head = a.wrap(function(bufnr, root)
    for _, choice in ipairs(choices) do
        local args = { 'git' }
        if root then
            vim.list_extend(args, { '-C', root })
        end
        vim.list_extend(args, choice.args)

        local res = a.system(args, { text = true }).await()
        if res.code == 0 then
            local head = vim.trim(res.stdout)
            vim.b[bufnr].dotvim_git_head = choice.icon .. ' ' .. head

            a.schedule().await()
            vim.cmd('redrawstatus')

            return
        end
    end
end)

function M.load_head(bufnr, root)
    bufnr = bufnr or 0
    load_head(bufnr, root)
end

return M
