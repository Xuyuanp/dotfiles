local PostRead = { 'BufReadPost', 'BufNewFile' }

return {
    {
        'nvim-treesitter/nvim-treesitter',
        dependencies = {
            'nvim-treesitter/nvim-treesitter-context',
            'nvim-treesitter/nvim-treesitter-textobjects',
            'nvim-treesitter/playground',
            'RRethy/nvim-treesitter-textsubjects',
            {
                'JoosepAlviste/nvim-ts-context-commentstring',
                config = function()
                    vim.g.skip_ts_context_commentstring_module = true
                end,
            },
        },
        build = ':TSUpdate',
        event = PostRead,
        config = function()
            require('dotvim.config.treesitter').setup()
        end,
    },

    {
        'haringsrob/nvim_context_vt',
        event = PostRead,
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        opts = {
            -- Enable by default. You can disable and use :NvimContextVtToggle to manually enable.
            -- Default: true
            enabled = true,
            -- Disable virtual text for given filetypes
            -- Default: { 'markdown' }
            disable_ft = { 'markdown' },
            -- Disable display of virtual text below blocks for indentation based languages like Python
            -- Default: false
            disable_virtual_lines = false,
            -- Same as above but only for specific filetypes
            -- Default: {}
            disable_virtual_lines_ft = { 'yaml', 'python' },
            -- How many lines required after starting position to show virtual text
            -- Default: 1 (equals two lines total)
            min_rows = 80,
        },
    },

    {
        'm-demare/hlargs.nvim',
        event = PostRead,
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        opts = {},
    },
}
