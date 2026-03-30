local M = {}

--- copy from https://github.com/williamboman/nvim-config/blob/main/lua/wb/lsp/on-attach.lua
function M.codelens()
    local bufnr = vim.api.nvim_get_current_buf()
    local winnr = vim.api.nvim_get_current_win()
    local row, col = unpack(vim.api.nvim_win_get_cursor(winnr))
    local lnum = row - 1 -- convert to 0-indexed to match LSP range
    local lenses = vim.lsp.codelens.get({ bufnr = bufnr })

    lenses = vim.tbl_filter(function(item)
        return item.lens.range.start.line <= lnum
    end, lenses)

    if #lenses == 0 then
        vim.notify('Could not find codelens to run.', vim.log.levels.WARN)
        return
    end

    table.sort(lenses, function(a, b)
        return a.lens.range.start.line > b.lens.range.start.line
    end)

    local nearest = lenses[1].lens
    vim.api.nvim_win_set_cursor(winnr, { nearest.range.start.line + 1, nearest.range.start.character })
    vim.lsp.codelens.run()
    vim.api.nvim_win_set_cursor(winnr, { row, col }) -- restore cursor
end

local _mt = {
    __index = function(obj, key)
        local f = vim.lsp.buf[key]
        rawset(obj, key, f)
        return f
    end,
}

return setmetatable(M, _mt)
