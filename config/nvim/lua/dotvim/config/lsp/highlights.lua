local vim = vim
local api = vim.api

local M = {}

function M.setup(highlight_map)
    require('dotvim.util').on_lsp_attach(function()
        -- stylua: ignore
        highlight_map = vim.tbl_deep_extend('keep', highlight_map or {}, {
            File        = 'Comment',
            Module      = 'Include',
            Namespace   = 'Structure',
            Package     = 'Include',
            Class       = 'Structure',
            Method      = 'Function',
            Property    = 'Identifier',
            Field       = 'Identifier',
            Constructor = 'Function',
            Enum        = 'Structure',
            Interface   = 'Structure',
            Function    = 'Function',
            Variable    = 'Identifier',
            Constant    = 'Constant',
            String      = 'String',
            Number      = 'Number',
            Boolean     = 'Boolean',
            Array       = 'Type',
            Object      = 'Identifier',
            Key         = 'Keyword',
            Null        = 'SpecialChar',
            EnumMember  = 'Constant',
            Struct      = 'Structure',
            Event       = 'Special',
            Operator    = 'Operator',
        })

        for kind, hl_group in pairs(highlight_map) do
            vim.api.nvim_set_hl(0, 'LspKind' .. kind, { link = hl_group, default = true })
        end
    end, { once = true, desc = 'Setup LspKind highlights' })
end

local escapeKey = string.char(27)

-- ansi color style codes
local styles = {
    bold = 1,
    italic = 3,
    underlined = 4,
    reverse = 7,
}

-- return { 'rr', 'gg', 'bb' }
local function parse_rgb(hl)
    local code = string.format('%x', hl)
    return vim.iter(code:gmatch('%x%x'))
        :map(function(v)
            return tonumber(v, 16)
        end)
        :totable()
end

function M.get_ansi_color_by_hl_name(name)
    local hl = api.nvim_get_hl(0, { name = name, link = false })
    local params = {}
    if hl.fg then
        table.insert(params, '38') -- foreground
        table.insert(params, '2') -- rgb format
        vim.list_extend(params, parse_rgb(hl.fg))
    end
    if hl.bg then
        table.insert(params, '48') -- background
        table.insert(params, '2') -- rgb format
        vim.list_extend(params, parse_rgb(hl.bg))
    end
    for style, id in pairs(styles) do
        if hl[style] then
            table.insert(params, id)
        end
    end
    return table.concat(params, ';')
end

function M.wrap_text_in_hl_name(text, hl_name)
    local ansi_params = M.get_ansi_color_by_hl_name(hl_name)
    return string.format('%s[%sm%s%s[0m', escapeKey, ansi_params, text, escapeKey)
end

return M
