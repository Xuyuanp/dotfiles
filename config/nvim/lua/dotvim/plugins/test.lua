return {
    {
        'echasnovski/mini.test',
        version = '*',
        lazy = false,
        config = true,
    },

    {
        'nvim-neotest/neotest',
        dependencies = {
            'nvim-neotest/nvim-nio',
            'nvim-lua/plenary.nvim',
            'nvim-treesitter/nvim-treesitter',
        },
        cmd = 'Neotest',
        config = function()
            require('dotvim.config.neotest').setup()
        end,
    },

    {
        'nvim-neotest/neotest-go',
        ft = 'go',
        config = function()
            ---@diagnostic disable-next-line: missing-fields
            require('dotvim.config.neotest').setup({
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
        'andythigpen/nvim-coverage',
        dependencies = 'nvim-lua/plenary.nvim',
        cmd = { 'Coverage' },
        config = function()
            require('coverage').setup({
                signs = {
                    covered = { priority = 100, text = '█' },
                    uncovered = { priority = 100, text = '█' },
                    partial = { priority = 100, text = '█' },
                },
                lang = {
                    go = {
                        coverage_file = '.tmp/coverage.txt',
                    },
                },
            })
        end,
    },
}
