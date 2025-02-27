local features = require('dotvim.features')

return {
    {
        'CopilotC-Nvim/CopilotChat.nvim',
        branch = 'main',
        cmd = { 'CopilotChat', 'Howto' },
        dependencies = {
            'zbirenbaum/copilot.lua',
            'nvim-lua/plenary.nvim',
        },
        build = 'make tiktoken', -- Only on MacOS or Linux
        opts = {},
        config = function(_, opts)
            require('CopilotChat').setup(opts)
        end,
    },

    {
        'olimorris/codecompanion.nvim',
        cmd = {
            'CodeCompanion',
            'CodeCompanionChat',
            'CodeCompanionActions',
        },
        keys = {
            { '<A-g>', '<cmd>CodeCompanionChat Toggle<CR>', mode = { 'n', 'i' }, desc = '[AI] CodeCompanionChat toggle' },
        },
        dependencies = {
            {
                'MeanderingProgrammer/render-markdown.nvim',
                optional = true,
                ft = { 'markdown', 'codecompanion' },
                opts = {
                    file_types = { 'codecompanion' },
                },
            },
        },
        init = function()
            vim.cmd('cabbrev cc  CodeCompanion')
            vim.cmd('cabbrev ccc CodeCompanionChat')
            vim.cmd('cabbrev cca CodeCompanionActions')

            require('dotvim.config.ai'):init()
        end,
        opts = {
            strategies = {
                chat = {
                    roles = {
                        llm = ' Copilot',
                    },
                },
            },
            display = {
                chat = {
                    start_in_insert_mode = true, -- Open the chat buffer in insert mode?
                    window = {
                        layout = 'float',
                        height = 0.8,
                        width = 0.8,
                        border = 'rounded',
                        relative = 'win',
                    },
                },
            },
        },
        specs = {
            {
                'saghen/blink.cmp',
                optional = true,
                opts = {
                    sources = {
                        providers = {
                            codecompanion = {
                                name = 'CodeCompanion',
                                module = 'codecompanion.providers.completion.blink',
                                score_offset = 100,

                                -- extra
                                filetypes = { 'codecompanion' },
                            },
                        },
                    },
                },
            },
        },
    },

    {
        'Exafunction/codeium.nvim',
        cond = features.codeium,
        cmd = 'Codeium',
        opts = {},
        specs = {
            {
                'saghen/blink.cmp',
                optional = true,
                dependencies = {
                    'Exafunction/codeium.nvim',
                    'saghen/blink.compat',
                },
                opts_extend = { 'sources.default' },
                opts = {
                    appearance = {
                        kind_icons = {
                            Codeium = '󰘦',
                        },
                    },
                    sources = {
                        default = { 'codeium' },
                        providers = {
                            codeium = {
                                name = 'codeium',
                                module = 'blink.compat.source',
                                score_offset = 100,
                                async = true,
                                max_items = 1,

                                -- extra
                                kind = 'Codeium',
                            },
                        },
                    },
                },
            },
        },
    },
}
