return {
    {
        'nvim-neotest/neotest',
        dependencies = {
            'nvim-lua/plenary.nvim',
            'nvim-treesitter/nvim-treesitter',
        },
        config = function()
            require('dotvim.config.neotest').setup()
        end,
    },

    {
        'nvim-neotest/neotest-go',
        ft = 'go',
        config = function()
            require('neotest').setup({
                adapters = {
                    require('neotest-go')({
                        experimental = {
                            test_table = true,
                        },
                        args = { '-count=1', '-race', '-timeout=60s' },
                    }),
                },
            })
        end,
    },

    {
        'rouge8/neotest-rust',
        ft = 'rust',
        config = function()
            require('neotest').setup({
                adapters = {
                    require('neotest-rust')({
                        args = { '--no-capture' },
                    }),
                },
            })
        end,
    },
}
