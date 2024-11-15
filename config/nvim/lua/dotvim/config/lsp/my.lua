local handlers = require('dotvim.config.lsp.handlers')

local M = setmetatable({}, {
    __index = function(_, key)
        return function(...)
            vim.lsp.buf[key](...)
        end
    end,
})

function M.references()
    vim.lsp.buf.references(nil, { on_list = handlers.new_on_list('References') })
end

function M.implementation()
    vim.lsp.buf.implementation({ on_list = handlers.new_on_list('Implementation') })
end

function M.definition()
    vim.lsp.buf.definition({ on_list = handlers.new_on_list('Definition') })
end

function M.type_definition()
    vim.lsp.buf.type_definition({ on_list = handlers.new_on_list('Type Definition') })
end

function M.signature_help()
    vim.lsp.buf.signature_help({ border = 'rounded' })
end

function M.hover()
    local ok, ufo = pcall(require, 'ufo')
    if ok then
        local winid = ufo.peekFoldedLinesUnderCursor()
        if winid then
            return
        end
    end

    vim.lsp.buf.hover({ border = 'rounded' })
end

function M.code_action(...)
    local ok, actions_preview = pcall(require, 'actions-preview')
    if ok then
        actions_preview.code_actions(...)
    else
        vim.lsp.buf.code_action(...)
    end
end

--- copy from https://github.com/williamboman/nvim-config/blob/main/lua/wb/lsp/on-attach.lua
function M.codelens()
    local bufnr = vim.api.nvim_get_current_buf()
    local winnr = vim.api.nvim_get_current_win()
    local row, col = unpack(vim.api.nvim_win_get_cursor(winnr))
    local lenses = vim.lsp.codelens.get(bufnr)

    lenses = vim.tbl_filter(function(lense)
        return lense.range.start.line < row
    end, lenses)

    if #lenses == 0 then
        vim.notify('Could not find codelens to run.', vim.log.levels.WARN)
        return
    end

    table.sort(lenses, function(a, b)
        return a.range.start.line > b.range.start.line
    end)

    vim.api.nvim_win_set_cursor(winnr, { lenses[1].range.start.line + 1, lenses[1].range.start.character })
    vim.lsp.codelens.run()
    vim.api.nvim_win_set_cursor(winnr, { row, col }) -- restore cursor
end

return M
