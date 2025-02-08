local lazy_require = require('dotvim.util').lazy_require
return {
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
                lazy_require('neochat').toggle,
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
                        model = 'deepseek-chat',
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
        'Xuyuanp/sqlx-rs.nvim',
        ft = { 'rust' },
        cmd = { 'SqlxFormat' },
        build = function()
            vim.fn.system({
                'pip',
                'install',
                '-U',
                'sqlparse',
            })
        end,
        opts = {},
        config = function(_, opts)
            local sqlx = require('sqlx')
            sqlx.setup(opts)

            vim.api.nvim_create_autocmd('BufWritePre', {
                pattern = '*.rs',
                group = vim.api.nvim_create_augroup('dotvim.sqlx-rs', { clear = true }),
                command = 'SqlxFormat',
                desc = '[sqlx-rs] format on save',
            })
        end,
    },

    {
        'Xuyuanp/yanil',
        dev = true,
        branch = 'main',
        keys = {
            { '<C-e>', require('dotvim.util').lazy_require('yanil.canvas').toggle, mode = 'n', desc = '[Yanil] toggle' },
        },
        config = function()
            require('dotvim.config.yanil').setup()

            local group_id = vim.api.nvim_create_augroup('dotvim.yanil', { clear = true })
            vim.api.nvim_create_autocmd({ 'BufEnter' }, {
                group = group_id,
                desc = 'Auto quit yanil',
                pattern = { 'Yanil' },
                command = 'if len(nvim_list_wins()) ==1 | q | endif',
            })

            vim.api.nvim_create_autocmd('User', {
                pattern = 'GitSignsUpdate',
                group = group_id,
                desc = 'Auto refresh git status of Yanil',
                callback = function()
                    require('yanil.git').update()
                end,
            })
        end,
    },

    {
        'Xuyuanp/floaterm.nvim',
        keys = {
            {
                '<A-o>',
                lazy_require('floaterm').toggle,
                mode = { 'n', 't' },
                desc = '[Floaterm] toggle',
            },
        },
        opts = {},
    },
}
