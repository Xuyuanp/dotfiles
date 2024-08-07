local vim = vim
local api = vim.api

local dotutil = require('dotvim.util')

local M = {}

local ANSI_CODES = {
    ESCAPE = string.char(27),
    FOREGROUND = '38',
    BACKGROUND = '48',
    RGB = '2',
}

-- ansi color style codes
local styles = {
    bold = 1,
    italic = 3,
    underlined = 4,
    reverse = 7,
}

---@return number[] rgb # format: { r, g, b }
local function parse_rgb(hl)
    local code = string.format('%x', hl)
    return vim.iter(code:gmatch('%x%x'))
        :map(function(v)
            return tonumber(v, 16)
        end)
        :totable()
end

---@param hl_info vim.api.keyset.hl_info
---@return string
local function hl2ansi(hl_info)
    local params = {}
    if hl_info.fg then
        table.insert(params, ANSI_CODES.FOREGROUND)
        table.insert(params, ANSI_CODES.RGB)
        vim.list_extend(params, parse_rgb(hl_info.fg))
    end
    if hl_info.bg then
        table.insert(params, ANSI_CODES.BACKGROUND)
        table.insert(params, ANSI_CODES.RGB)
        vim.list_extend(params, parse_rgb(hl_info.bg))
    end
    for style, id in pairs(styles) do
        if hl_info[style] then
            table.insert(params, id)
        end
    end
    return table.concat(params, ';')
end

---@param hl_name string
---@return string
function M.get_ansi_color_by_hl_name(hl_name)
    local hl = api.nvim_get_hl(0, { name = hl_name, link = false })
    return hl2ansi(hl)
end

---@type table<string, string>
M.ansi_colors = dotutil.new_cache_table(M.get_ansi_color_by_hl_name)

-- flush cache when colorscheme changed
vim.api.nvim_create_autocmd('ColorScheme', {
    callback = function()
        M.ansi_colors = dotutil.new_cache_table(M.get_ansi_color_by_hl_name)
    end,
})

---@param text string
---@param hl_name string
---@return string
function M.wrap_text_in_hl_name(text, hl_name)
    return string.format('%s[%sm%s%s[0m', ANSI_CODES.ESCAPE, M.ansi_colors[hl_name], text, ANSI_CODES.ESCAPE)
end

return M
