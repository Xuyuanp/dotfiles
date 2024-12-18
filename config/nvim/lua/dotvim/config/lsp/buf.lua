local buf = {}

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
                horizontal = {
                    preview_width = 0.5,
                },
            },
            sorting_strategy = 'ascending',
            results_title = '',
        })
        :find()
end

---@param opts? mylsp.OnListOpts
---@return fun(list: vim.lsp.LocationOpts.OnList)
local function new_on_list(opts)
    opts = opts or {}

    ---@param list vim.lsp.LocationOpts.OnList
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

local function with_default_opts(f, default, n)
    n = n or 1
    default = default or {}
    return function(...)
        local params = { ... }
        local opts = params[n] or {}
        local default_opts = type(default) == 'function' and default() or default
        params[n] = vim.tbl_deep_extend('force', default_opts, opts)
        return f(unpack(params, 1, n))
    end
end

---@generic Opts: vim.lsp.ListOpts
---@param opts? mylsp.OnListOpts
---@return Opts
local function location_opts(opts)
    return {
        on_list = new_on_list(opts),
    }
end

local function floating_opts()
    local max_width = math.ceil(vim.o.columns * 0.8) - 4
    local width = math.min(80, max_width)
    local default = {
        border = 'rounded',
        width = width,
        max_width = max_width,
        title_pos = 'center',
    }
    return default
end

buf.references = with_default_opts(
    vim.lsp.buf.references,
    location_opts({
        title = 'References',
        always_select = true,
    }),
    2
)

buf.implementation = with_default_opts(
    vim.lsp.buf.implementation,
    location_opts({
        title = 'Implementation',
    })
)

buf.definition = with_default_opts(
    vim.lsp.buf.definition,
    location_opts({
        title = 'Definition',
    })
)

buf.type_definition = with_default_opts(
    vim.lsp.buf.type_definition,
    location_opts({
        title = 'Type Definition',
    })
)

buf.signature_help = with_default_opts(vim.lsp.buf.signature_help, floating_opts)

buf.hover = with_default_opts(vim.lsp.buf.hover, floating_opts)

local code_action_backup = vim.lsp.buf.code_action
---@param opts? vim.lsp.buf.code_action.Opts
function buf.code_action(opts)
    local ok, actions_preview = pcall(require, 'actions-preview')
    if ok then
        actions_preview.code_actions(opts)
    else
        code_action_backup(opts)
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

buf.document_symbol = with_default_opts(
    vim.lsp.buf.document_symbol,
    location_opts({
        title = 'Symbols',
        always_select = true,
        tel_opts = {
            custom_entry_maker = custom_entry_maker,
        },
    })
)

buf.workspace_symbol = with_default_opts(
    vim.lsp.buf.workspace_symbol,
    location_opts({
        title = 'Symbols',
        always_select = true,
        tel_opts = {
            custom_entry_maker = custom_entry_maker,
        },
    }),
    2
)

buf.outgoing_calls = with_default_opts(vim.lsp.buf.outgoing_calls)
buf.incoming_calls = with_default_opts(vim.lsp.buf.incoming_calls)

buf.format = with_default_opts(vim.lsp.buf.format)

local M = {
    _backup = {},
}

function M.overwrite()
    for k, v in pairs(buf) do
        M._backup[k] = vim.lsp.buf[k]
        vim.lsp.buf[k] = v
    end
end

function M.restore()
    for k, v in pairs(M._backup) do
        vim.lsp.buf[k] = v
    end
end

return M
