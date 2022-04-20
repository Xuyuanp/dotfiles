local replace_termcodes = vim.api.nvim_replace_termcodes

local M = {}

local function t(key)
    return replace_termcodes(key, true, true, true)
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

    cmp.setup({
        snippet = {
            expand = function(args)
                vim.fn['vsnip#anonymous'](args.body)
            end,
        },
        mapping = {
            ['<C-p>'] = cmp.mapping.select_prev_item(),
            ['<C-n>'] = cmp.mapping.select_next_item(),
            ['<C-Space>'] = cmp.mapping.complete(),
            ['<CR>'] = cmp.mapping.confirm({
                behavior = cmp.ConfirmBehavior.Insert,
                select = false,
            }),
            ['<C-e>'] = nil,
            ['<Tab>'] = function(fallback)
                if cmp.visible() then
                    cmp.select_next_item()
                elseif vim.fn['vsnip#available']() == 1 then
                    vim.fn.feedkeys(t('<Plug>(vsnip-expand-or-jump)'), '')
                else
                    fallback()
                end
            end,
            ['<S-Tab>'] = function(fallback)
                if cmp.visible() then
                    cmp.select_next_item()
                elseif vim.fn['vsnip#available']() == 1 then
                    vim.fn.feedkeys(t('<Plug>(vsnip-jump-prev)'), '')
                else
                    fallback()
                end
            end,
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
        preselect = cmp.PreselectMode.None,
        sources = cmp.config.sources({
            { name = 'nvim_lsp' },
        }, {
            { name = 'buffer', keyword_length = 5 },
            { name = 'path' },
            { name = 'tmux', keyword_length = 5 },
            { name = 'calc' },
        }, {
            { name = 'vsnip' },
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
            ghost_text = true,
        },
    })

    cmp.setup.cmdline('/', {
        sources = {
            { name = 'buffer' },
        },
    })

    local cmp_git = vim.F.npcall(require, 'cmp_git')
    if cmp_git then
        cmp_git.setup()
        cmp.setup.filetype('gitcommit', {
            sources = cmp.config.sources({
                { name = 'cmp_git' },
            }, {
                { name = 'buffer' },
                { name = 'vsnip' },
            }),
        })
    end

    cmp.setup.filetype('lua', {
        sources = cmp.config.sources({
            { name = 'nvim_lua' },
            { name = 'nvim_lsp' },
        }, {
            { name = 'buffer' },
            { name = 'vsnip' },
        }),
    })

    local crates = vim.F.npcall(require, 'crates')
    if crates then
        crates.setup()
        cmp.setup.filetype('toml', {
            sources = cmp.config.sources({
                { name = 'crates' },
            }, {
                { name = 'buffer' },
                { name = 'vsnip' },
            }),
        })
    end

    cmp.register_source('helm', require('dotvim.cmp.helm'))
    cmp.setup.filetype('helm', {
        sources = cmp.config.sources({
            { name = 'helm' }
        })
    })

    local autopair_cmp = vim.F.npcall(require, 'nvim-autopairs.completion.cmp')
    if autopair_cmp then
        cmp.event:on('confirm_done', autopair_cmp.on_confirm_done({}))
    end
end

return M
