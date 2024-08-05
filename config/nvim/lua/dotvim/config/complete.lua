local M = {}

local function has_words_before()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match('%s') == nil
end

local function toCamelCase(str)
    return str:gsub('(%a)(%w*)', function(first, rest)
        return first:upper() .. rest:lower()
    end)
end

function M.setup()
    local cmp = require('cmp')
    local compare = require('cmp.config.compare')
    local types = require('cmp.types')

    local compare_kind = function(entry1, entry2)
        local kind1 = entry1:get_kind()
        kind1 = kind1 == types.lsp.CompletionItemKind.Text and 100 or kind1
        local kind2 = entry2:get_kind()
        kind2 = kind2 == types.lsp.CompletionItemKind.Text and 100 or kind2
        if kind1 ~= kind2 then
            local diff = kind1 - kind2
            if diff < 0 then
                return true
            elseif diff > 0 then
                return false
            end
        end
    end

    local luasnip = require('luasnip')
    local lspkind = require('lspkind')

    cmp.setup({
        completion = {
            completeopt = 'menu,menuone,noinsert',
        },

        snippet = {
            expand = function(args)
                luasnip.lsp_expand(args.body)
            end,
        },
        mapping = {
            ['<C-p>'] = cmp.mapping.select_prev_item(),
            ['<C-n>'] = cmp.mapping.select_next_item(),
            ['<C-b>'] = cmp.mapping.scroll_docs(-5),
            ['<C-f>'] = cmp.mapping.scroll_docs(5),
            ['<C-Space>'] = cmp.mapping.complete(),
            ['<CR>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.confirm({ behavior = types.cmp.ConfirmBehavior.Replace, select = false })
                else
                    fallback()
                end
            end),
            ['<C-e>'] = cmp.mapping.close(),
            ['<Tab>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.select_next_item()
                elseif luasnip.expand_or_jumpable() then
                    luasnip.expand_or_jump()
                elseif has_words_before() then
                    cmp.complete()
                else
                    fallback()
                end
            end, { 'i', 's' }),
            ['<S-Tab>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                    cmp.select_prev_item()
                elseif luasnip.jumpable(-1) then
                    luasnip.jump(-1)
                else
                    fallback()
                end
            end, { 'i', 's' }),
        },
        window = {
            documentation = {
                border = 'rounded',
                winhighlight = 'Normal:NormalFloat,FloatBorder:FloatBorder,CursorLine:Visual,Search:None',
                zindex = 1001,
            },
        },
        formatting = {
            fields = { 'abbr', 'kind', 'menu' },
            expandable_indicator = true,
            format = lspkind.cmp_format({
                mode = 'symbol_text',
                maxwidth = 50,
                menu = setmetatable({
                    nvim_lsp = '[LSP]',
                    luasnip = '[LuaSnip]',
                }, {
                    __index = function(obj, key)
                        rawset(obj, key, '[' .. toCamelCase(key) .. ']')
                        return rawget(obj, key)
                    end,
                }),
            }),
        },
        preselect = cmp.PreselectMode.Item,
        sources = cmp.config.sources({
            { name = 'codeium' },
            { name = 'nvim_lsp' },
            { name = 'luasnip' },
            { name = 'lazydev', group_index = 0 },
        }, {
            { name = 'buffer', keyword_length = 5 },
            { name = 'path' },
            { name = 'tmux', keyword_length = 5 },
            { name = 'calc' },
        }),
        sorting = {
            priority_weight = 2,
            comparators = {
                compare.offset,
                compare.exact,
                compare.score,
                compare.recently_used,
                compare_kind,
                compare.sort_text,
                compare.length,
                compare.order,
            },
        },
        experimental = {
            ghost_text = {
                hl_group = 'LspCodeLens',
            },
        },
    })

    local ok, autopair_cmp = pcall(require, 'nvim-autopairs.completion.cmp')
    if ok then
        cmp.event:on('confirm_done', autopair_cmp.on_confirm_done({ map_char = { tex = '' } }))
    end
end

return M
