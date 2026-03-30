local M = {}

---@type table<string, fun(match: table<integer,TSNode[]>, pattern: integer, source: integer|string, predicate: any[], metadata: vim.treesitter.query.TSMetadata)>
local custom_directives = {
    ['absoffset!'] = function(match, _, source, pred, metadata)
        local capture_id = pred[2]
        local nodes = match[capture_id]
        if not nodes or #nodes == 0 then
            return
        end

        if not metadata[capture_id] then
            metadata[capture_id] = {}
        end

        -- get_range applies offset! adjustments (0.12+: reads .offset; <0.12: reads .range)
        -- returns Range6: {start_row, start_col, start_byte, end_row, end_col, end_byte}
        local range = vim.treesitter.get_range(nodes[1], source, metadata[capture_id])

        local start_row_offset = pred[3] or 0
        local start_col_offset = pred[4] or 0
        local end_row_offset = pred[5] or 0
        local end_col_offset = pred[6] or 0

        local sr = range[1] + start_row_offset
        local sc = range[2] + start_col_offset
        local er = sr + end_row_offset
        local ec = sc + end_col_offset

        -- If this produces an invalid range, we just skip it.
        if sr < er or (sr == er and sc <= ec) then
            metadata[capture_id].range = { sr, sc, range[3], er, ec, range[6] }
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
    vim.treesitter.query.add_predicate('is-mise?', function(_, _, bufnr, _)
        local filepath = vim.api.nvim_buf_get_name(tonumber(bufnr) or 0)
        local filename = vim.fn.fnamemodify(filepath, ':t')
        return string.match(filename, '.*mise.*%.toml$') ~= nil
    end, { force = true, all = false })
end

function M.setup(opts)
    M.register_custom_directives()

    require('nvim-treesitter').setup(opts)

    local installed = require('nvim-treesitter').get_installed('parsers')

    vim.api.nvim_create_autocmd('FileType', {
        group = vim.api.nvim_create_augroup('dotvim.treesitter', { clear = true }),
        callback = function(ev)
            local ft = ev.match
            local lang = vim.treesitter.language.get_lang(ft)
            if not lang then
                return
            end

            if not vim.tbl_contains(installed, lang) then
                return
            end

            pcall(vim.treesitter.start)
            if ft ~= 'yaml' and ft ~= 'helm' then
                vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end
        end,
    })
end

return M
