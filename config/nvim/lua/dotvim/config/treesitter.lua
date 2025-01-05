local M = {}

local custom_directives = {
    ['absoffset!'] = function(match, _, _, pred, metadata)
        ---@cast pred integer[]
        local capture_id = pred[2]
        if not metadata[capture_id] then
            metadata[capture_id] = {}
        end

        local range = metadata[capture_id].range or { match[capture_id]:range() }
        local start_row_offset = pred[3] or 0
        local start_col_offset = pred[4] or 0
        local end_row_offset = pred[5] or 0
        local end_col_offset = pred[6] or 0

        range[1] = range[1] + start_row_offset
        range[2] = range[2] + start_col_offset -- offset from start of row
        range[3] = range[1] + end_row_offset
        range[4] = range[2] + end_col_offset -- offset from start of col

        -- If this produces an invalid range, we just skip it.
        if range[1] < range[3] or (range[1] == range[3] and range[2] <= range[4]) then
            metadata[capture_id].range = range
        end
    end,
}

function M.register_custom_directives()
    for name, handler in pairs(custom_directives) do
        vim.treesitter.query.add_directive(name, handler, { force = true })
    end
end

function M.setup(opts)
    M.register_custom_directives()

    local ts_configs = require('nvim-treesitter.configs')
    ts_configs.setup(opts)
end

return M
