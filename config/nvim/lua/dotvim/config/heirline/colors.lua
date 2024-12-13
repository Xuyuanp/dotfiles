local M = {}

local function get_highlight(name)
    return vim.api.nvim_get_hl(0, { name = name, link = false })
end

-- stylua: ignore
local _COLORS = {
    black        = '#202020',
    black2       = '#282828',
    black_pure   = '#000000',
    gray         = '#808080',
    gray_dark    = '#353535',
    gray_darker  = '#505050',
    gray_light   = '#c0c0c0',
    white        = '#ffffff',

    aqua         = '#8ec07c',

    tan          = '#f4c069',

    red          = '#ee4a59',
    red_dark     = '#a80000',
    red_light    = '#ff4090',

    orange       = '#ff8900',
    orange_light = '#f0af00',

    yellow       = '#f0df33',

    green        = '#77ff00',
    green_dark   = '#35de60',
    green_light  = '#a0ff70',

    blue         = '#7090ff',
    cyan         = '#33efff',
    ice          = '#49a0f0',
    teal         = '#00d0c0',
    turqoise     = '#2bff99',

    magenta      = '#cc0099',
    pink         = '#ffa6ff',
    purple       = '#cf55f0',

    magenta_dark = '#bb0099',
    pink_light   = '#ffb7b7',
    purple_light = '#af60af',

    diag_warn    = get_highlight('DiagnosticWarn').fg,
    diag_error   = get_highlight('DiagnosticError').fg,
    diag_hint    = get_highlight('DiagnosticHint').fg,
    diag_info    = get_highlight('DiagnosticInfo').fg,
    git_del      = get_highlight('@diff.minus').fg,
    git_add      = get_highlight('@diff.plus').fg,
    git_change   = get_highlight('@diff.delta').fg,
}

function M.get()
    return _COLORS
end

function M.update()
    _COLORS.diag_warn = get_highlight('DiagnosticWarn').fg
    _COLORS.diag_error = get_highlight('DiagnosticError').fg
    _COLORS.diag_hint = get_highlight('DiagnosticHint').fg
    _COLORS.diag_info = get_highlight('DiagnosticInfo').fg
    _COLORS.git_del = get_highlight('@diff.minus').fg
    _COLORS.git_add = get_highlight('@diff.plus').fg
    _COLORS.git_change = get_highlight('@diff.delta').fg
end

return M
