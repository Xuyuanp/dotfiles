return {
    {
        'tpope/vim-surround',
        event = { 'BufReadPost', 'BufNewFile' },
    },
    {
        'mg979/vim-visual-multi',
        event = { 'BufReadPost', 'BufNewFile' },
    },

    {
        'windwp/nvim-autopairs',
        event = { 'BufReadPost', 'BufNewFile' },
        config = function()
            local npairs = require('nvim-autopairs')
            npairs.setup()

            local Rule = require('nvim-autopairs.rule')
            npairs.add_rules({
                Rule(' ', ' '):with_pair(function(opts)
                    local pair = opts.line:sub(opts.col - 1, opts.col)
                    return vim.tbl_contains({ '()', '[]', '{}', '<>' }, pair)
                end),
                Rule('( ', ' )')
                    :with_pair(function()
                        return false
                    end)
                    :with_move(function(opts)
                        return opts.prev_char:match('.%)') ~= nil
                    end)
                    :use_key(')'),
                Rule('{ ', ' }')
                    :with_pair(function()
                        return false
                    end)
                    :with_move(function(opts)
                        return opts.prev_char:match('.%}') ~= nil
                    end)
                    :use_key('}'),
                Rule('[ ', ' ]')
                    :with_pair(function()
                        return false
                    end)
                    :with_move(function(opts)
                        return opts.prev_char:match('.%]') ~= nil
                    end)
                    :use_key(']'),
                Rule('< ', ' >')
                    :with_pair(function()
                        return false
                    end)
                    :with_move(function(opts)
                        return opts.prev_char:match('.%>') ~= nil
                    end)
                    :use_key('>'),
            })
        end,
    },

    {
        'junegunn/vim-easy-align',
        -- stylua: ignore
        keys = {
            { '<CR><Space>',   ':EasyAlign\\<CR>',   mode = 'v' },
            { '<CR>2<Space>',  ':EasyAlign2\\<CR>',  mode = 'v' },
            { '<CR>-<Space>',  ':EasyAlign-\\<CR>',  mode = 'v' },
            { '<CR>-2<Space>', ':EasyAlign-2\\<CR>', mode = 'v' },
            { '<CR>:',         ':EasyAlign:<CR>',    mode = 'v' },
            { '<CR>=',         ':EasyAlign=<CR>',    mode = 'v' },
            { '<CR><CR>=',     ':EasyAlign!=<CR>',   mode = 'v' },
            { '<CR>"',         ':EasyAlign"<CR>',    mode = 'v' },
        },
    },

    {
        'dstein64/vim-startuptime',
        cmd = 'StartupTime',
    },

    {
        'voldikss/vim-translator',
        cmd = {
            'Translate',
            'TranslateH',
            'TranslateL',
            'TranslateR',
            'TranslateW',
            'TranslateX',
        },
        init = function()
            vim.g.translator_history_enable = true
        end,
    },

    {
        'jbyuki/venn.nvim',
        keys = {
            { '<Leader>vb', ':<C-e>VBox<CR>', mode = 'v', desc = '[Venn] draw vbox' },
        },
    },

    {
        'folke/snacks.nvim',
        lazy = false,
        priority = 1000,
        opts = {
            bigfile = { enabled = true },
            quickfile = { enabled = true },
            notifier = { enabled = true },
            input = {
                enabled = true,
                win = {
                    relative = 'cursor',
                    row = -3,
                    col = 0,
                    noautocmd = false,
                },
            },
            indent = {},
            image = {},
        },
    },

    {
        'folke/flash.nvim',
        keys = {
            {
                's',
                mode = { 'n', 'x', 'o' },
                function()
                    require('flash').jump()
                end,
                desc = 'Flash',
            },
            {
                'S',
                mode = { 'n', 'x', 'o' },
                function()
                    require('flash').treesitter()
                end,
                desc = 'Flash Treesitter',
            },
            {
                '<C-s>',
                mode = { 'c' },
                function()
                    require('flash').toggle()
                end,
                desc = 'Toggle Flash Search',
            },
        },
        opts = {},
    },

    {
        'max397574/colortils.nvim',
        cmd = 'Colortils',
        config = function()
            require('colortils').setup({})
        end,
    },

    {
        'keaising/im-select.nvim',
        cond = vim.fn.has('mac') == 1,
        commit = '6425bea', -- lock to a specific commit
        event = 'InsertEnter',
        config = function()
            require('im_select').setup({})
        end,
    },

    {
        'nvim-mini/mini.ai',
        version = '*',
        lazy = false,
        opts = {},
    },
}
