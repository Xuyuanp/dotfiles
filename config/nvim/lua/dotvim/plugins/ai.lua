local features = require('dotvim.features')

return {
    {
        'jackMort/ChatGPT.nvim',
        cmd = 'ChatGPT',
        config = function()
            require('chatgpt').setup({
                -- optional configuration
            })
        end,
        dependencies = {
            'MunifTanjim/nui.nvim',
            'nvim-lua/plenary.nvim',
            'nvim-telescope/telescope.nvim',
        },
    },

    {
        'Xuyuanp/neochat.nvim',
        dev = true,
        build = function()
            vim.fn.system({
                'pip',
                'install',
                '-U',
                'openai',
            })
        end,
        keys = {
            {
                '<A-g>',
                require('dotvim.util').lazy_require('neochat').toggle,
                mode = { 'n', 'i' },
                desc = '[NeoChat] toggle',
                noremap = false,
            },
        },
        dependencies = {
            'MunifTanjim/nui.nvim',
            'f/awesome-chatgpt-prompts',
            'nvim-telescope/telescope.nvim',
        },
        cmd = 'NeoChatExplainCode',
        config = function()
            require('neochat').setup({
                bot_text = 'Bot:',
                bot_sign = '',
                user_text = 'You:',
                user_sign = '',
                spinners = 'line',
                openai = {
                    chat_completions = {
                        model = 'gpt-3.5-turbo',
                    },
                },
            })

            vim.api.nvim_create_user_command('NeoChatExplainCode', function(args)
                local ft = vim.bo.filetype
                if not ft then
                    return
                end

                local code_block = vim.api.nvim_buf_get_lines(0, args.line1 - 1, args.line2, false)
                local input = { 'Explain the following code', '```' .. ft }
                vim.list_extend(input, code_block)
                vim.list_extend(input, { '```' })

                require('neochat').open(input)
            end, {
                desc = '[NeoChat] explain code',
                range = true,
            })
        end,
    },

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
            require('dotvim.config.howto').setup()
        end,
    },

    {
        'olimorris/codecompanion.nvim',
        cmd = {
            'CodeCompanion',
            'CodeCompanionChat',
            'CodeCompanionActions',
        },
        opts = {},
    },

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

    {
        'zbirenbaum/copilot.lua',
        cond = features.copilot,
        cmd = 'Copilot',
        opts = {},
    },

    {
        'Exafunction/codeium.nvim',
        cond = features.codeium,
        cmd = 'Codeium',
        opts = {},
    },
}
