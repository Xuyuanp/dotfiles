local M = {}

---@type table<string, fun(match: table<integer,TSNode[]>, pattern: integer, source: integer|string, predicate: any[], metadata: vim.treesitter.query.TSMetadata)>
local custom_directives = {
    ['absoffset!'] = function(_match, _, _, pred, metadata)
        local capture_id = pred[2]
        if not metadata[capture_id] then
            return
        end

        local range = metadata[capture_id].range
        if not range then
            return
        end
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
    ['set-ref!'] = function(_match, _, _, pred, metadata)
        -- (#set-ref! foo @bar)
        local key = pred[2]
        local ref = pred[3]
        local val = metadata[ref].text
        metadata[key] = val
    end,
    ['inject-lang-ref!'] = function(_match, _, _, pred, metadata)
        -- (#inject-lang-ref! @_cap.lang)
        local ref = pred[2]
        local val = metadata[ref].text
        if not val then
            return
        end
        local _, _, lang = val:find('lang:(%w+!?)')
        if not lang then
            return
        end
        local format = vim.endswith(lang, '!')
        if format then
            metadata['format'] = 1
            lang = lang:sub(1, -2)
        end
        metadata['injection.language'] = lang
    end,
    ['inject-lang!'] = function(_match, _, _, pred, metadata)
        -- (#inject-lang-ref! "json!")
        local lang = pred[2]
        local format = vim.endswith(lang, '!')
        if format then
            metadata['format'] = 1
            lang = lang:sub(1, -2)
        end
        metadata['injection.language'] = lang
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
