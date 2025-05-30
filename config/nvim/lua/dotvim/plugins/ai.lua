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
        'zbirenbaum/copilot.lua',
        opts = {
            suggestion = { enabled = false },
            panel = { enabled = false },
        },
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
                        url = 'http://localhost:8080/api',
                    },
                    schema = {
                        model = {
                            default = 'gpt-4.1',
                        },
                    },
                }),
                nes = require('codecompanion.adapters').extend('openai_compatible', {
                    name = 'nes',
                    formatted_name = 'Nes',
                    env = {
                        api_key = 'OPENAI_API_KEY',
                        url = 'http://localhost:8080/api',
                    },
                    schema = {
                        model = {
                            default = 'gpt-4o-mini',
                        },
                    },
                }),
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

    {
        'copilotlsp-nvim/copilot-lsp',
        lazy = false,
        config = false,
        init = function()
            vim.g.copilot_nes_debounce = 400
            -- vim.lsp.enable('copilot_ls')
            vim.lsp.enable('copilot-ls') -- use my own copilot ls

            local function request_nes()
                require('copilot-lsp.nes').request_nes('nes')
            end

            local debounced_fn = require('copilot-lsp.util').debounce(request_nes, 400)
            local group = vim.api.nvim_create_augroup('dotvim.copilot-lsp.nes', { clear = true })
            vim.api.nvim_create_autocmd({ 'TextChangedI' }, {
                group = group,
                desc = '[Nes] auto trigger',
                callback = function()
                    debounced_fn()
                end,
            })
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
