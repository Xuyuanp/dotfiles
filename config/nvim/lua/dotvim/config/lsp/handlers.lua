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
