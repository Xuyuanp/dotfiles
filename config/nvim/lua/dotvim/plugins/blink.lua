local M = {
    {
        'saghen/blink.cmp',
        dependencies = {
            'rafamadriz/friendly-snippets',
        },
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
                trigger = {
                    show_on_blocked_trigger_characters = function()
                        if vim.bo.filetype == 'go' then
                            return { ':' }
                        end

                        return { ' ', '\n', '\t' }
                    end,
                },
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
                        fallbacks = { 'lsp' },

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
            require('dotvim.config.coding.blink').setup(opts)
        end,
    },

    {
        'saghen/blink.compat',
        version = '*',
        opts = {},
    },

    {
        'andersevenrud/cmp-tmux',
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
    } or {},

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
