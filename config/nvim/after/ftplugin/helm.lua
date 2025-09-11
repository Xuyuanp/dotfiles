local ts = vim.treesitter

local scopes = {
    if_action = 'if',
    with_action = 'with',
    range_action = 'range',
}

local ns_id = vim.api.nvim_create_namespace('dotvim.helm.scopes')

---@param node TSNode
local function dfs(node)
    local node_type = node:type()
    if scopes[node_type] then
        local row_start, _, row_end = node:range()
        vim.api.nvim_buf_set_extmark(0, ns_id, row_end, 0, {
            virt_text = { { string.format('end of %s: %d', scopes[node_type], row_start + 1), 'Comment' } },
        })
    end
    for child in node:iter_children() do
        dfs(child)
    end
end

local function hint_scopes(bufnr)
    local parser = ts.get_parser(bufnr, 'helm')
    if not parser then
        return
    end
    vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
    parser:parse()
    parser:for_each_tree(function(tstree, _ltree)
        dfs(tstree:root())
    end)
end

vim.api.nvim_create_autocmd({ 'BufRead', 'InsertLeave', 'TextChanged', 'CursorHold' }, {
    buffer = 0,
    callback = function(args)
        hint_scopes(args.buf)
    end,
})

vim.api.nvim_create_autocmd({ 'TextChangedI' }, {
    buffer = 0,
    callback = function()
        vim.api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
    end,
})
