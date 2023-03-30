local M = {}

local function has_words_before()
    local line, col = unpack(vim.api.nvim_win_get_cursor(0))
    return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match('%s') == nil
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
                    cmp.confirm({ behavior = types.cmp.ConfirmBehavior.Replace, select = true })
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
            format = (function()
                local ok, lspkind = pcall(require, 'lspkind')
                if ok then
                    return lspkind.cmp_format()
                end
            end)(),
        },
        preselect = cmp.PreselectMode.Item,
        sources = cmp.config.sources({
            { name = 'copilot' },
            { name = 'nvim_lsp' },
            { name = 'luasnip' },
        }, {
            { name = 'buffer', keyword_length = 5 },
            { name = 'path' },
            { name = 'tmux', keyword_length = 5 },
            { name = 'calc' },
        }),
        sorting = {
            priority_weight = 2,
            comparators = {
                require('copilot_cmp.comparators').prioritize,
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
            ghost_text = true,
        },
    })

    local crates = vim.F.npcall(require, 'crates')
    if crates then
        crates.setup()
        cmp.setup.filetype('toml', {
            sources = cmp.config.sources({
                { name = 'crates' },
                { name = 'nvim_lsp' },
            }, {
                { name = 'buffer' },
                { name = 'luasnip' },
            }),
        })
    end

    local autopair_cmp = vim.F.npcall(require, 'nvim-autopairs.completion.cmp')
    if autopair_cmp then
        cmp.event:on('confirm_done', autopair_cmp.on_confirm_done({}))
    end
end

return M
