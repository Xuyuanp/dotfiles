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

local function transform_items_for_kind(kind)
    return function(_, items)
        local CompletionItemKind = require('blink.cmp.types').CompletionItemKind
        local kind_idx = #CompletionItemKind + 1
        CompletionItemKind[kind_idx] = kind
        for _, item in ipairs(items) do
            item.kind = kind_idx
        end
        return items
    end
end

local function overwrite_default_capabilities()
    local default_capabilities = require('dotvim.config.lsp.capabilities')
    local blink_capabilities = require('blink.cmp').get_lsp_capabilities()
    if not vim.deep_equal(default_capabilities, blink_capabilities) then
        vim.notify_once('Blink capabilities are different from default capabilities', vim.log.levels.WARN)

        local source = 'return ' .. vim.inspect(blink_capabilities, { indent = '    ' })
        local fname = vim.fs.normalize('~/.config/nvim/lua/dotvim/config/lsp/capabilities.lua')

        local uv = vim.uv
        local fd = uv.fs_open(fname, 'w', 0644)
        assert(fd, 'Failed to open file ' .. fname)
        uv.fs_write(fd, source)
        uv.fs_close(fd)
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
                per_filetype = {
                    DressingInput = {}, -- disable completion for DressingInput filetype
                },
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
        opts_extend = { 'sources.default' },
        config = function(_, opts)
            local ft_providers = {}
            for name, provider in pairs(opts.sources.providers) do
                if provider.kind then
                    provider.transform_items = transform_items_for_kind(provider.kind)
                    provider.kind = nil
                end

                for _, ft in ipairs(provider.filetypes or {}) do
                    ft_providers[ft] = ft_providers[ft] or {}
                    table.insert(ft_providers[ft], name)
                end
                provider.filetypes = nil
            end

            opts.sources.per_filetype = opts.sources.per_filetype or {}
            for ft, names in pairs(ft_providers) do
                local old = opts.sources.per_filetype[ft]
                if not old then
                    opts.sources.per_filetype[ft] = append_default(opts.sources.default, names)
                elseif #old > 0 then
                    opts.sources.per_filetype[ft] = append_default(old, names)
                end
            end
            require('blink.cmp').setup(opts)

            overwrite_default_capabilities()
        end,
    },

    {
        'saghen/blink.compat',
        version = '*',
        opts = {},
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
                        default = { 'copilot' },
                        providers = {
                            copilot = {
                                name = 'Github',
                                module = 'blink-cmp-copilot',
                                score_offset = 100,
                                async = true,

                                -- extra
                                kind = 'Copilot',
                            },
                        },
                    },
                },
            }
        or nil,

    {
        'andersevenrud/cmp-tmux',
        cond = vim.env.TMUX,
    },

    vim.env.TMUX and {
        'saghen/blink.cmp',
        optional = true,
        dependencies = {
            'andersevenrud/cmp-tmux',
        },
        opts = {
            sources = {
                default = { 'tmux' },
                providers = {
                    tmux = {
                        name = 'tmux',
                        module = 'blink.compat.source',
                        max_items = 5,
                        min_keyword_length = 5,
                        score_offset = -4,
                        async = true,
                    },
                },
            },
        },
    } or nil,

    {
        'saghen/blink.cmp',
        optional = true,
        dependencies = {
            'hrsh7th/cmp-calc',
        },
        opts = {
            sources = {
                default = { 'calc' },
                providers = {
                    calc = {
                        name = 'calc',
                        module = 'blink.compat.source',
                        score_offset = -1,
                    },
                },
            },
        },
    },
}

return M
