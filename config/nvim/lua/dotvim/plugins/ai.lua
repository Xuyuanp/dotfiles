local features = require('dotvim.features')

return {
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
            strategies = {
                chat = {
                    roles = {
                        llm = function(adapter)
                            local formatted = require('dotvim.config.ai.codecompanion').format_adapter(adapter)
                            return formatted
                        end,
                        user = ' Me',
                    },
                    keymaps = {
                        change_adapter = {
                            modes = {
                                n = '<A-m>',
                            },
                        },
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
                        opts = {
                            number = false,
                        },
                    },
                },
            },
            opts = {
                log_level = 'TRACE',
                system_prompt = function(_opts)
                    -- the default system prompt talks shit
                    -- local language = opts.language or 'English'
                    return string.format([[You are a helpful AI programming assistant.]])
                end,
            },
        },
        config = function(_, opts)
            opts = opts or {}

            opts.adapters = vim.tbl_deep_extend('force', {
                http = {
                    openrouter = require('codecompanion.adapters').extend('openai_compatible', {
                        name = 'openrouter',
                        formatted_name = 'OpenRouter',
                        icon = '󰃻',
                        env = {
                            api_key = 'OPENROUTER_API_KEY',
                            url = 'https://openrouter.ai/api',
                        },
                        schema = {
                            model = {
                                default = 'deepseek/deepseek-chat-v3-0324',
                            },
                        },
                    }),
                    copilot = require('codecompanion.adapters').extend('openai_compatible', {
                        name = 'copilot',
                        formatted_name = 'Copilot',
                        icon = '',
                        env = {
                            api_key = 'OPENAI_API_KEY',
                            url = vim.env.OPENAI_BASE_URL,
                            chat_url = '/chat/completions',
                            models_endpoint = '/models',
                        },
                        schema = {
                            model = {
                                default = 'gpt-5',
                            },
                        },
                    }),
                    nes = require('codecompanion.adapters').extend('openai_compatible', {
                        name = 'nes',
                        formatted_name = 'Nes',
                        env = {
                            api_key = 'OPENAI_API_KEY',
                            url = vim.env.OPENAI_BASE_URL,
                            chat_url = '/chat/completions',
                            models_endpoint = '/models',
                        },
                        schema = {
                            model = {
                                default = 'gpt-4o-mini',
                            },
                        },
                    }),
                },
            }, opts.adapters or {})
            require('codecompanion').setup(opts)
        end,
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
                    extensions = {
                        mcphub = {
                            callback = 'mcphub.extensions.codecompanion',
                            opts = {
                                -- MCP Tools
                                make_tools = true, -- Make individual tools (@server__tool) and server groups (@server) from MCP servers
                                show_server_tools_in_chat = true, -- Show individual tools in chat completion (when make_tools=true)
                                add_mcp_prefix_to_tool_names = false, -- Add mcp__ prefix (e.g `@mcp__github`, `@mcp__neovim__list_issues`)
                                show_result_in_chat = true, -- Show tool results directly in chat buffer
                                format_tool = nil, -- function(tool_name:string, tool: CodeCompanion.Agent.Tool) : string Function to format tool names to show in the chat buffer
                                -- MCP Resources
                                make_vars = true, -- Convert MCP resources to #variables for prompts
                                -- MCP Prompts
                                make_slash_commands = true, -- Add MCP prompts as /slash commands
                            },
                        },
                    },
                },
            },
        },
    },

    {
        'copilotlsp-nvim/copilot-lsp',
        lazy = false,
        config = false,
        init = function()
            vim.g.copilot_nes_debounce = 400
            vim.lsp.enable('copilot_ls', false)
        end,
        keys = {
            {
                '<A-i>',
                function()
                    require('copilot-lsp.nes').request_nes('nes')
                end,
                mode = 'i',
                desc = '[Nes] get suggestion',
            },
            {
                '<A-n>',
                function()
                    local _ = require('copilot-lsp.nes').apply_pending_nes() and require('copilot-lsp.nes').walk_cursor_end_edit()
                end,
                mode = 'i',
                desc = '[Nes] apply suggestion',
            },
        },
    },
}
