return {
    {
        'nvim-treesitter/nvim-treesitter',
        dependencies = {
            'nvim-treesitter/nvim-treesitter-textobjects',
            'RRethy/nvim-treesitter-textsubjects',
            {
                'JoosepAlviste/nvim-ts-context-commentstring',
                init = function()
                    vim.g.skip_ts_context_commentstring_module = true
                end,
            },
        },
        build = ':TSUpdate',
        event = 'VeryLazy',
        config = function()
            require('dotvim.config.treesitter').setup()
        end,
    },
}
