local features = require('dotvim.features')

local function append_default(default, names)
    names = vim.islist(names) and names or { names }
    if type(default) == 'function' then
        return function(...)
            local original = default(...)
            return vim.list_extend(original, names)
        end
    else
        local original = vim.deepcopy(default)
        return vim.list_extend(original, names)
    end
end

local M = {
    {
        'saghen/blink.cmp',
        dependencies = {
            'rafamadriz/friendly-snippets',
        },
        cond = features.blink,
        version = '*',
        event = { 'InsertEnter' },
        -- init = function()
        --     ---@diagnostic disable-next-line: duplicate-set-field
        --     vim.g.dotvim_lsp_capabilities = function()
        --         return require('blink.cmp').get_lsp_capabilities()
        --     end
        -- end,
        ---@module 'blink.cmp'
        ---@type blink.cmp.Config
        opts = {
            keymap = {
                preset = 'enter',
            },
            appearance = {
                nerd_font_variant = 'mono',
                kind_icons = {
                    Codeium = '󱃖',
                    -- crates.nvim
                    Feature = '󰩉',
                    Version = '',
                },
            },
            completion = {
                documentation = {
                    auto_show = true,
                    window = { border = 'rounded' },
                },
                menu = {
                    draw = {
                        treesitter = { 'lsp', 'copilot' },
                        align_to_component = 'label', -- or 'none' to disable
                        padding = 1,
                        gap = 4,
                        columns = {
                            { 'label', 'label_description', gap = 1 },
                            { 'kind_icon', 'kind', gap = 1 },
                            { 'source_name' },
                        },
                    },
                },
                ghost_text = { enabled = true },
            },
            signature = { enabled = true, window = { border = 'rounded' } },
            sources = {
                default = { 'lsp', 'path', 'snippets', 'buffer' },
                cmdline = {},
                providers = {
                    lazydev = {
                        name = 'LazyDev',
                        module = 'lazydev.integrations.blink',
                        -- make lazydev completions top priority (see `:h blink.cmp`)
                        score_offset = 100,

                        filetypes = { 'lua' },
                    },
                    buffer = {
                        min_keyword_length = 5,
                        max_items = 5,
                    },
                    snippets = {
                        max_items = 5,
                    },
                },
            },
        },
        config = function(_, opts)
            local ft_providers = {}
            for name, provider in pairs(opts.sources.providers) do
                if provider.kind then
                    local kind = provider.kind
                    provider.transform_items = function(_, items)
                        local CompletionItemKind = require('blink.cmp.types').CompletionItemKind
                        local kind_idx = #CompletionItemKind + 1
                        CompletionItemKind[kind_idx] = kind
                        for _, item in ipairs(items) do
                            item.kind = kind_idx
                        end
                        return items
                    end
                    provider.kind = nil
                end

                if provider.default then
                    opts.sources.default = append_default(opts.sources.default, name)
                end
                provider.default = nil

                for _, ft in ipairs(provider.filetypes or {}) do
                    ft_providers[ft] = ft_providers[ft] or {}
                    table.insert(ft_providers[ft], name)
                end
                provider.filetypes = nil
            end

            opts.sources.per_filetype = opts.sources.per_filetype or {}
            for ft, names in pairs(ft_providers) do
                opts.sources.per_filetype[ft] = append_default(opts.sources.per_filetype[ft] or opts.sources.default, names)
            end
            require('blink.cmp').setup(opts)

            local default_capabilities = require('dotvim.config.lsp.capabilities')
            local blink_capabilities = require('blink.cmp').get_lsp_capabilities()
            if not vim.deep_equal(default_capabilities, blink_capabilities) then
                vim.notify_once('Blink capabilities are different from default capabilities', vim.log.levels.WARN)

                local source = 'return ' .. vim.inspect(blink_capabilities, { indent = '    ' })
                local fname = vim.fs.normalize('~/.config/nvim/lua/dotvim/config/lsp/capabilities.lua')

                local uv = vim.uv
                local fd = uv.fs_open(fname, 'w', 0644)
                assert(fd, 'Failed to open file')
                uv.fs_write(fd, source)
                uv.fs_close(fd)
            end
        end,
    },
    {
        'giuxtaposition/blink-cmp-copilot',
        cond = features.copilot and features.blink,
        dependencies = {
            'zbirenbaum/copilot.lua',
            opts = {
                suggestion = { enabled = false },
                panel = { enabled = false },
            },
        },
    },
    features.copilot
            and {
                'saghen/blink.cmp',
                optional = true,
                opts = {
                    appearance = {
                        kind_icons = {
                            Copilot = '',
                        },
                    },
                    sources = {
                        providers = {
                            copilot = {
                                name = 'Github',
                                module = 'blink-cmp-copilot',
                                score_offset = 100,
                                async = true,

                                -- extra
                                kind = 'Copilot',
                                default = true,
                            },
                        },
                    },
                },
            }
        or nil,

    {
        'saghen/blink.compat',
        version = '*',
        opts = {},
    },
}

return M
