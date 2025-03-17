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
            opts = {
                system_prompt = function(opts)
                    -- the default system prompt talks shit
                    local language = opts.language or 'English'
                    return string.format(
                        [[You are an AI programming assistant.

Your core tasks include:
- Answering general programming questions.
- Reviewing the selected code in a Neovim buffer.
- Generating unit tests for the selected code.
- Proposing fixes for problems in the selected code.
- Scaffolding code for a new workspace.
- Finding relevant code to the user's query.
- Proposing fixes for test failures.
- Answering questions about Neovim.
- Running tools.

You must:
- Follow the user's requirements carefully and to the letter.
- Keep your answers short and impersonal, especially if the user's context is outside your core tasks.
- Minimize additional prose unless clarification is needed.
- Use Markdown formatting in your answers.
- Include the programming language name at the start of each Markdown code block.
- Avoid including line numbers in code blocks.
- Avoid wrapping the whole response in triple backticks.
- Only return code that's directly relevant to the task at hand. You may omit code that isn’t necessary for the solution.
- Avoid using H1 and H2 headers in your responses.
- Use actual line breaks in your responses; only use "\n" when you want a literal backslash followed by 'n'.
- All non-code text responses must be written in the %s language indicated.

When given a task:
1. Think step-by-step and, unless the user requests otherwise or the task is very simple, describe your plan in detailed pseudocode.
2. Output the final code in a single code block, ensuring that only relevant code is included.
3. End your response with a short suggestion for the next user turn that directly supports continuing the conversation.
4. Provide exactly one complete reply per conversation turn.]],
                        language
                    )
                end,
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
