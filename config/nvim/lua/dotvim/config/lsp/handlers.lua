local vim = vim
local api = vim.api

local symbol_kinds = vim.lsp.protocol.SymbolKind

local dotutil = require('dotvim.util')

local highlights = require('dotvim.config.lsp.highlights')

local fzf_run = dotutil.fzf_run
local fzf_wrap = dotutil.fzf_wrap

local M = {}

---@type table<string, string>
local symbol_highlights = dotutil.new_cache_table(function(kind)
    return 'CmpItemKind' .. kind
end)

function M.symbol_handler(err, result, ctx)
    if err or not result or vim.tbl_isempty(result) then
        return
    end

    local bufname = api.nvim_buf_get_name(ctx.bufnr or 0)

    local source = {}

    local draw_symbols
    draw_symbols = function(symbols, depth)
        for _, symbol in ipairs(symbols) do
            local kind = symbol_kinds[symbol.kind]
            local line
            if symbol.location then
                -- for SymbolInformation
                line = string.format(
                    '%s\t%d\t%d\t%s[%s]: %s',
                    vim.uri_to_fname(symbol.location.uri),
                    symbol.location.range.start.line + 1,
                    symbol.location.range['end'].line + 1,
                    string.rep('  ', depth),
                    kind,
                    highlights.wrap_text_in_hl_name(symbol.name, symbol_highlights[kind])
                )
            else
                -- for DocumentSymbols
                line = string.format(
                    '%s\t%d\t%d\t%s[%s]: %s %s',
                    bufname,
                    symbol.range.start.line + 1,
                    symbol.range['end'].line + 1,
                    string.rep('  ', depth),
                    kind,
                    highlights.wrap_text_in_hl_name(symbol.name, symbol_highlights[kind]),
                    highlights.wrap_text_in_hl_name(symbol.detail or '', 'SpecialComment')
                )
            end
            table.insert(source, line)

            draw_symbols(symbol.children or {}, depth + 1)
        end
    end

    draw_symbols(result, 0)

    local wrapped = fzf_wrap('document_symbols', {
        source = source,
        options = {
            '+m',
            '+x',
            '--tiebreak=index',
            '--ansi',
            '-d',
            '\t',
            '--with-nth',
            '4..',
            '--cycle',
            '--reverse',
            '--color',
            'dark',
            '--prompt',
            'LSP DocumentSymbols> ',
            '--preview',
            'bat --highlight-line={2}:{3} --color=always --map-syntax=vimrc:VimL {1}',
            '--preview-window',
            '+{2}-10',
        },
        sink = function(line)
            if not line or type(line) ~= 'string' or string.len(line) == 0 then
                return
            end
            local parts = vim.fn.split(line, '\t')
            local filename = parts[1]
            local linenr = parts[2]
            if filename ~= bufname then
                api.nvim_command('e ' .. filename)
            end
            vim.fn.execute('normal! ' .. linenr .. 'zz')
        end,
    })

    fzf_run(wrapped)
end

function M.new_on_list(title)
    return function(list)
        M.on_list(list, { title = title })
    end
end

function M.on_list(list, opts)
    opts = opts or {}
    -- stolen from vim.lsp.buf.get_locations
    local win = api.nvim_get_current_win()
    local from = vim.fn.getpos('.')
    local tagname = vim.fn.expand('<cword>')

    local function jump_to_item(item)
        local b = item.bufnr or vim.fn.bufadd(item.filename)

        -- Save position in jumplist
        vim.cmd("normal! m'")
        -- Push a new item into tagstack
        local tagstack = { { tagname = tagname, from = from } }
        vim.fn.settagstack(vim.fn.win_getid(win), { items = tagstack }, 't')

        vim.bo[b].buflisted = true
        local w = vim.fn.win_findbuf(b)[1] or win
        api.nvim_win_set_buf(w, b)
        api.nvim_win_set_cursor(w, { item.lnum, item.col - 1 })
        vim._with({ win = w }, function()
            -- Open folds under the cursor
            vim.cmd('normal! zv')
        end)
    end

    if #list.items == 1 then
        jump_to_item(list.items[1])
        return
    end

    local source = {}
    for i, item in ipairs(list.items) do
        local fname_display = vim.fn.fnamemodify(item.filename, ':~:.')
        local start_line = item.lnum
        local end_line = item.end_lnum or item.lnum
        local line = string.format(
            '%s\t%d\t%d\t%d\t%s |%d ~ %d| %s',
            item.filename,
            start_line,
            end_line,
            i,
            fname_display,
            start_line,
            end_line,
            vim.trim(item.text)
        )
        table.insert(source, line)
    end

    local title = opts.title or list.title

    local wrapped = fzf_wrap(title, {
        source = source,
        options = {
            '+m',
            '+x',
            '--tiebreak=index',
            '--ansi',
            '-d',
            '\t',
            '--with-nth',
            '5..',
            '--reverse',
            '--color',
            'dark',
            '--prompt',
            'LSP ' .. title .. '> ',
            '--preview',
            'bat --highlight-line={2}:{3} --color=always --map-syntax=vimrc:VimL {1}',
            '--preview-window',
            '+{2}-10',
        },
        sink = function(line)
            if not line or type(line) ~= 'string' or string.len(line) == 0 then
                return
            end
            local parts = vim.fn.split(line, '\t')
            local choice = tonumber(parts[4])
            local item = list.items[choice]

            jump_to_item(item)
        end,
    })

    fzf_run(wrapped)
end

function M.outgoing_calls(err, result, ctx)
    if err or not result then
        return
    end

    local direction = 'to'

    local bufname = api.nvim_buf_get_name(ctx.bufnr or 0)

    table.sort(result, function(call1, call2)
        return call1.fromRanges[1].start.line < call2.fromRanges[1].start.line
    end)

    local symbol_kinds = vim.lsp.protocol.SymbolKind

    local source = {}

    for _, call_hierarchy_call in pairs(result) do
        local item = call_hierarchy_call[direction]
        local kind = symbol_kinds[item.kind]
        table.insert(
            source,
            string.format(
                '%s\t%d\t%d\t[%s]: %s %s',
                vim.uri_to_fname(item.uri),
                item.range.start.line + 1,
                item.range['end'].line + 1,
                kind,
                highlights.wrap_text_in_hl_name(item.name, symbol_highlights[kind]),
                highlights.wrap_text_in_hl_name(item.detail or '', 'SpecialComment')
            )
        )
    end

    local wrapped = fzf_wrap('document_symbols', {
        source = source,
        options = {
            '+m',
            '+x',
            '--tiebreak=index',
            '--ansi',
            '-d',
            '\t',
            '--with-nth',
            '4..',
            '--cycle',
            '--reverse',
            '--color',
            'dark',
            '--prompt',
            'LSP OutgoingCalls> ',
            '--preview',
            'bat --highlight-line={2}:{3} --color=always --map-syntax=vimrc:VimL {1}',
            '--preview-window',
            '+{2}-10',
        },
        sink = function(line)
            if not line or type(line) ~= 'string' or string.len(line) == 0 then
                return
            end
            local parts = vim.fn.split(line, '\t')
            local filename = parts[1]
            local linenr = parts[2]
            if filename ~= bufname then
                api.nvim_command('e ' .. filename)
            end
            vim.fn.execute('normal! ' .. linenr .. 'zz')
        end,
    })

    fzf_run(wrapped)
end

return M
