local handlers = require('dotvim.config.lsp.handlers')

local M = setmetatable({}, {
    __index = function(obj, key)
        local f = vim.lsp.buf[key]
        rawset(obj, key, f)
        return f
    end,
})

---@generic Opts: vim.lsp.ListOpts
---@param opts? Opts
---@return Opts
local function location_opts(opts, title)
    local default = {
        on_list = handlers.new_on_list(title),
    }
    opts = vim.tbl_extend('force', default, opts or {})
    return opts
end

---@param context? table
---@param opts? vim.lsp.ListOpts
function M.references(context, opts)
    local opts = location_opts(opts, 'References')
    vim.lsp.buf.references(context, opts)
end

---@param opts? vim.lsp.LocationOpts
function M.implementation(opts)
    local opts = location_opts(opts, 'Implementation')
    vim.lsp.buf.implementation(opts)
end

---@param opts? vim.lsp.LocationOpts
function M.definition(opts)
    local opts = location_opts(opts, 'Definition')
    vim.lsp.buf.definition(opts)
end

---@param opts? vim.lsp.LocationOpts
function M.type_definition(opts)
    local opts = location_opts(opts, 'Type Definition')
    vim.lsp.buf.type_definition(opts)
end

---@generic Opts: vim.lsp.util.open_floating_preview.Opts
---@param opts? Opts
---@return Opts
local function floating_opts(opts)
    local max_width = math.ceil(vim.o.columns * 0.8) - 4
    local width = math.min(80, max_width)
    local default = {
        border = 'rounded',
        width = width,
        max_width = max_width,
    }
    opts = vim.tbl_extend('force', default, opts or {})
    return opts
end

---@param opts? vim.lsp.buf.signature_help.Opts
function M.signature_help(opts)
    opts = floating_opts(opts)
    vim.lsp.buf.signature_help(opts)
end

---@param opts? vim.lsp.buf.hover.Opts
function M.hover(opts)
    local ok, ufo = pcall(require, 'ufo')
    if ok then
        local winid = ufo.peekFoldedLinesUnderCursor()
        if winid then
            return
        end
    end
    opts = floating_opts(opts)
    opts.title = 'Hover'
    opts.title_pos = 'center'
    vim.lsp.buf.hover(opts)
end

---@param opts? vim.lsp.buf.code_action.Opts
function M.code_action(opts)
    local ok, actions_preview = pcall(require, 'actions-preview')
    if ok then
        actions_preview.code_actions(opts)
    else
        vim.lsp.buf.code_action(opts)
    end
end

---@param opts? vim.lsp.ListOpts
function M.document_symbol(opts)
    -- currently not support custom handler in opts
    vim.lsp.buf.document_symbol(opts)
end

---@param query? string
---@param opts? vim.lsp.ListOpts
function M.workspace_symbol(query, opts)
    vim.lsp.buf.workspace_symbol(query, opts)
end

function M.outgoing_calls()
    vim.lsp.buf.outgoing_calls()
end

function M.incoming_calls()
    vim.lsp.buf.incoming_calls()
end

---@param min_level integer
---@return function
local function suppress_notify(min_level)
    local notify = vim.notify
    ---@diagnostic disable-next-line: duplicate-set-field
    vim.notify = function(msg, level, opts)
        if not level or level <= min_level then
            return
        end
        notify(msg, level, opts)
    end
    return function()
        vim.notify = notify
    end
end

---@param opts? vim.lsp.buf.format.Opts
function M.format(opts)
    -- suppress no clients found warning
    local restore = suppress_notify(vim.log.levels.WARN)
    vim.lsp.buf.format(opts)
    restore()
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
