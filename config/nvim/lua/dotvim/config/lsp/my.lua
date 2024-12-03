local a = require('dotvim.util.async')

local M = {}

---@class mylsp.ListContext
---@field method string
---@field bufnr number

---@class mylsp.List
---@field title? string
---@field context? mylsp.ListContext
---@field items vim.quickfix.entry[]

---@class mylsp.OnListOpts
---@field title? string Title of the list, default is 'Locations', prefix with 'Lsp '
---@field always_select? boolean Whether to always select the only item
---@field show_current? boolean Whether to show current item in the list
---@field tel_opts? table Telescope opts

---@class SymbolUserData
---@field depth number
---@field kind string
---@field deprecated boolean
---@field symbol lsp.DocumentSymbol | lsp.SymbolInformation

local lsp_type_highlight = {
    ['Class'] = 'TelescopeResultsClass',
    ['Constant'] = 'TelescopeResultsConstant',
    ['Field'] = 'TelescopeResultsField',
    ['Function'] = 'TelescopeResultsFunction',
    ['Method'] = 'TelescopeResultsMethod',
    ['Property'] = 'TelescopeResultsOperator',
    ['Struct'] = 'TelescopeResultsStruct',
    ['Variable'] = 'TelescopeResultsVariable',
}

---@param entry_maker fun(qf_entry: vim.quickfix.entry): table
---@param custom? fun(qf_entry: vim.quickfix.entry, entry: table): table
local function wrap_qf_entry_maker(entry_maker, custom)
    ---@param qf_entry vim.quickfix.entry
    ---@return table
    return function(qf_entry)
        local entry = entry_maker(qf_entry)
        entry.lnend = qf_entry.end_lnum
        entry.colend = qf_entry.end_col

        if custom then
            entry = custom(qf_entry, entry)
        end
        return entry
    end
end

---@param items vim.quickfix.entry[]
---@param opts? table telescope opts
local function telescope_pick_qflist(items, opts)
    opts = opts or {}

    local conf = require('telescope.config').values
    local finders = require('telescope.finders')
    local make_entry = require('telescope.make_entry')
    local pickers = require('telescope.pickers')

    local qf_entry_maker = make_entry.gen_from_quickfix(opts)
    local entry_maker = wrap_qf_entry_maker(qf_entry_maker, opts.custom_entry_maker)

    pickers
        .new(opts, {
            finder = finders.new_table({
                results = items,
                entry_maker = entry_maker,
            }),
            previewer = conf.qflist_previewer(opts),
            sorter = conf.generic_sorter(opts),
            push_cursor_on_edit = true,
            push_tagstack_on_edit = true,
            layout_strategy = 'flex',
            layout_config = {
                prompt_position = 'top',
            },
            sorting_strategy = 'ascending',
            results_title = '',
        })
        :find()
end

---@param opts? mylsp.OnListOpts
---@return fun(list: mylsp.List)
local function new_on_list(opts)
    opts = opts or {}

    ---@param list mylsp.List
    return function(list)
        local items = list.items
        if not opts.show_current then
            local bufnr = list.context and list.context.bufnr or 0
            local filepath = vim.api.nvim_buf_get_name(bufnr)
            local winnr = vim.fn.win_findbuf(bufnr)[1] or 0
            local lnum = vim.api.nvim_win_get_cursor(winnr)[1]
            items = vim.iter(items)
                :filter(function(item)
                    return not (item.filename == filepath and item.lnum == lnum)
                end)
                :totable()
        end
        if not items or #items == 0 then
            return
        end

        if #items == 1 and not opts.always_select then
            vim.fn.setqflist({}, ' ', { items = items })
            vim.cmd('silent cfirst')
            return
        end

        local tel_opts = vim.tbl_deep_extend('force', {
            prompt_title = 'Lsp ' .. (opts.title or 'Locations'),
        }, opts.tel_opts or {})

        telescope_pick_qflist(items, tel_opts)
    end
end

---@generic Opts: vim.lsp.ListOpts
---@param opts? Opts
---@param on_list_opts? mylsp.OnListOpts
---@return Opts
local function location_opts(opts, on_list_opts)
    local default = {
        on_list = new_on_list(on_list_opts),
    }
    opts = vim.tbl_extend('force', default, opts or {})
    return opts
end

---@param context? table
---@param opts? vim.lsp.ListOpts
function M.references(context, opts)
    local opts = location_opts(opts, { title = 'References', always_select = true })
    vim.lsp.buf.references(context, opts)
end

---@param opts? vim.lsp.LocationOpts
function M.implementation(opts)
    local opts = location_opts(opts, { title = 'Implementation' })
    vim.lsp.buf.implementation(opts)
end

---@param opts? vim.lsp.LocationOpts
function M.definition(opts)
    local opts = location_opts(opts, { title = 'Definition' })
    vim.lsp.buf.definition(opts)
end

function M.preview_definition(opts)
    local opts = location_opts(opts, { title = 'Preview Definition', always_select = true })
    vim.lsp.buf.definition(opts)
end

---@param opts? vim.lsp.LocationOpts
function M.type_definition(opts)
    local opts = location_opts(opts, { title = 'Type Definition' })
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

---@param symbols lsp.DocumentSymbol[]|lsp.SymbolInformation[]
---@param bufnr? integer
---@return vim.quickfix.entry[] # See |setqflist()| for the format
local function symbols_to_items(symbols, bufnr)
    bufnr = bufnr or 0

    local items = {} --- @type vim.quickfix.entry[]

    local dfs
    ---@param symbols lsp.DocumentSymbol[]|lsp.SymbolInformation[]
    ---@param depth number
    dfs = function(symbols, depth)
        if not symbols or vim.tbl_isempty(symbols) then
            return
        end

        for _, symbol in ipairs(symbols) do
            --- @type string?, lsp.Position?, lsp.Position?
            local filename, pos, end_pos
            local kind = vim.lsp.protocol.SymbolKind[symbol.kind] or 'Unknown'
            local user_data = {
                depth = depth,
                kind = kind,
                deprecated = vim.tbl_contains(symbol.tags or {}, 1) or symbol.deprecated,
                symbol = symbol,
            }

            if symbol.location then
                --- @cast symbol lsp.SymbolInformation
                filename = vim.uri_to_fname(symbol.location.uri)
                pos = symbol.location.range.start
                end_pos = symbol.location.range['end']
            elseif symbol.range then
                --- @cast symbol lsp.DocumentSymbol
                filename = vim.api.nvim_buf_get_name(bufnr)
                pos = symbol.range.start
                end_pos = symbol.range['end']
                user_data.detail = symbol.detail
            end

            if filename and pos then
                ---@type vim.quickfix.entry
                local item = {
                    filename = filename,
                    bufnr = bufnr,
                    lnum = pos.line + 1,
                    col = pos.character + 1,
                    text = string.format('[%s] %s', kind, symbol.name),
                    user_data = user_data,
                }
                if end_pos then
                    item.end_lnum = end_pos.line + 1
                    item.end_col = end_pos.character + 1
                end
                items[#items + 1] = item
            end

            dfs(symbol.children, depth + 1)
        end
    end

    dfs(symbols, 0)
    return items
end

-- NOTE: overwrite the default function
vim.lsp.util.symbols_to_items = symbols_to_items

local function custom_entry_maker(qf_entry, entry)
    local user_data = qf_entry.user_data --[[@type SymbolUserData?]]
    if not user_data or not user_data.symbol then
        return entry
    end
    local symbol = user_data.symbol

    entry.display = function()
        local hls = {}
        local text = ''

        local parts = {
            { string.rep('  ', user_data.depth) },
            { '[', 'TelescopeBorder' },
            { user_data.kind },
            { ']', 'TelescopeBorder' },
            { ' ' },
            { symbol.name, lsp_type_highlight[user_data.kind] },
            { ' ' },
            { symbol.detail or '', 'SpecialComment' },
        }

        for _, part in ipairs(parts) do
            if part[2] then
                hls[#hls + 1] = {
                    { text:len(), text:len() + #part[1] },
                    part[2],
                }
            end
            text = text .. part[1]
        end

        if user_data.deprecated then
            hls[#hls + 1] = {
                { user_data.depth * 2, text:len() },
                '@markup.strikethrough',
            }
        end

        return text, hls
    end

    return entry
end

function M.document_symbol(opts)
    local opts = location_opts(opts, {
        title = 'Symbols',
        always_select = true,
        tel_opts = {
            custom_entry_maker = custom_entry_maker,
        },
    })
    vim.lsp.buf.document_symbol(opts)
end

---@param query? string
---@param opts? vim.lsp.ListOpts
function M.workspace_symbol(query, opts)
    local opts = location_opts(opts, {
        title = 'Symbols',
        always_select = true,
        tel_opts = {
            custom_entry_maker = custom_entry_maker,
        },
    })
    a.run(function()
        if not query then
            query = a.ui.input('Query: ').await()
        end
        vim.lsp.buf.workspace_symbol(query, opts)
    end)
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

local _mt = {
    __index = function(obj, key)
        local f = vim.lsp.buf[key]
        rawset(obj, key, f)
        return f
    end,
}

return setmetatable(M, _mt)
