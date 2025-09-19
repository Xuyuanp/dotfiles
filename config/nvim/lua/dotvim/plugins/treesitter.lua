return {
    {
        'nvim-treesitter/nvim-treesitter',
        build = ':TSUpdate',
        branch = 'main',
        lazy = false,
        opts = {},
        config = function(_, opts)
            require('dotvim.config.treesitter').setup(opts)
        end,
    },

    {
        'nvim-treesitter/nvim-treesitter-textobjects',
        lazy = false,
        branch = 'main',
        opts = {},
        keys = {
            {
                'af',
                function()
                    require('nvim-treesitter-textobjects.select').select_textobject('@function.outer', 'textobjects')
                end,
                mode = { 'x', 'o' },
                desc = '',
            },
            {
                'if',
                function()
                    require('nvim-treesitter-textobjects.select').select_textobject('@function.inner', 'textobjects')
                end,
                mode = { 'x', 'o' },
                desc = '',
            },
            {
                'ac',
                function()
                    require('nvim-treesitter-textobjects.select').select_textobject('@class.outer', 'textobjects')
                end,
                mode = { 'x', 'o' },
                desc = '',
            },
            {
                'ic',
                function()
                    require('nvim-treesitter-textobjects.select').select_textobject('@class.inner', 'textobjects')
                end,
                mode = { 'x', 'o' },
                desc = '',
            },
            {
                'as',
                function()
                    require('nvim-treesitter-textobjects.select').select_textobject('@local.scope', 'locals')
                end,
                mode = { 'x', 'o' },
                desc = '',
            },
        },
    },

    {
        'JoosepAlviste/nvim-ts-context-commentstring',
        lazy = false,
        init = function()
            vim.g.skip_ts_context_commentstring_module = true
        end,
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        opts = {},
    },
}
