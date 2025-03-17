local features = require('dotvim.features')

return {
    {
        'CopilotC-Nvim/CopilotChat.nvim',
        version = '*',
        cmd = { 'CopilotChat' },
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
        version = '*',
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

            require('dotvim.config.ai.codecompanion').init_progress()
        end,
        opts = {
            adapters = {
                copilot = function()
                    return require('codecompanion.adapters').extend('copilot', {
                        icon = '',
                        schema = {
                            model = {
                                default = function()
                                    return vim.env.COPILOT_MODEL or 'gpt-4o-2024-11-20'
                                end,
                            },
                        },
                    })
                end,
            },
            strategies = {
                chat = {
                    roles = {
                        llm = function(adapter)
                            local formatted = require('dotvim.config.ai.codecompanion').format_adapter(adapter)
                            return 'CodeCompanion (' .. formatted .. ')'
                        end,
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
                        relative = 'editor',
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

    {
        'ravitemer/mcphub.nvim',
        dependencies = {
            'nvim-lua/plenary.nvim',
        },
        cmd = { 'MCPHub' },
        build = 'npm install -g mcp-hub@latest',
        opts = {
            port = 3000,
            config = vim.fn.expand('~/.config/mcp/mcpservers.json'),
        },
        specs = {
            {
                'olimorris/codecompanion.nvim',
                optional = true,
                dependencies = {
                    'ravitemer/mcphub.nvim',
                },
                opts = {
                    strategies = {
                        chat = {
                            tools = {
                                mcp = {
                                    callback = function()
                                        return require('mcphub.extensions.codecompanion')
                                    end,
                                    description = 'Call tools and resources from the MCP Servers',
                                    opts = {
                                        requires_approval = true,
                                    },
                                },
                            },
                        },
                    },
                },
            },
        },
    },
}
