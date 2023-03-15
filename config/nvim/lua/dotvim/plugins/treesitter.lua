return {
    {
        'nvim-treesitter/nvim-treesitter',
        dependencies = {
            'nvim-treesitter/playground',
            'romgrk/nvim-treesitter-context',
            'HiPhish/nvim-ts-rainbow2',
        },
        build = ':TSUpdate',
        event = { 'BufReadPost', 'BufNewFile' },
        config = function()
            require('dotvim.treesitter').setup()
        end,
    },
    {
        'haringsrob/nvim_context_vt',
        event = { 'BufReadPost', 'BufNewFile' },
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        config = function()
            require('nvim_context_vt').setup({
                -- Enable by default. You can disable and use :NvimContextVtToggle to maually enable.
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
            })
        end,
    },

    {
        'm-demare/hlargs.nvim',
        event = { 'BufReadPost', 'BufNewFile' },
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        config = function()
            require('hlargs').setup({})
        end,
    },
}
