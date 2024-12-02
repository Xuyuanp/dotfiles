local utils = require('heirline.utils')
local dotcolors = require('dotvim.util.colors')

local get_highlight = utils.get_highlight

local M = {}

function M.get()
    return vim.tbl_deep_extend('force', dotcolors.colors, {
        diag_warn = get_highlight('DiagnosticWarn').fg,
        diag_error = get_highlight('DiagnosticError').fg,
        diag_hint = get_highlight('DiagnosticHint').fg,
        diag_info = get_highlight('DiagnosticInfo').fg,
        git_del = get_highlight('@diff.minus').fg,
        git_add = get_highlight('@diff.plus').fg,
        git_change = get_highlight('@diff.delta').fg,
    })
end

return M
