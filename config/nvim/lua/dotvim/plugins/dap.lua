return {
    {
        'theHamsta/nvim-dap-virtual-text',
        dependencies = {
            'nvim-treesitter/nvim-treesitter',
        },
    },
    {
        'nvim-telescope/telescope-dap.nvim',
        dependencies = {
            'nvim-telescope/telescope.nvim',
        },
        config = function()
            require('telescope').load_extension('dap')
        end,
    },
    {
        'jay-babu/mason-nvim-dap.nvim',
        dependencies = { 'williamboman/mason.nvim' },
    },

    {
        'mfussenegger/nvim-dap',
        event = { 'BufReadPost', 'BufNewFile' },
        dependencies = {
            'nvim-neotest/nvim-nio',
            'nvim-lua/plenary.nvim',
            'rcarriga/nvim-dap-ui',
            'theHamsta/nvim-dap-virtual-text',
            'nvim-telescope/telescope-dap.nvim',
            { 'jay-babu/mason-nvim-dap.nvim', version = 'v2' },
        },
        config = function()
            require('dotvim.config.dap').setup()
            require('dotvim.config.dap').ui.setup()
            require('dotvim.config.dap').virtual_text.setup()

            -- required
            vim.schedule(function()
                require('mason-nvim-dap').setup({
                    ensure_installed = {},
                    automatic_installation = false,
                    automatic_setup = {
                        filetypes = {
                            python = false,
                            rust = false,
                        },
                    },
                    handlers = {
                        function(config)
                            local options = config.adapters.options or {}
                            options.initialize_timeout_sec = 60
                            config.adapters.options = options

                            require('mason-nvim-dap').default_setup(config)
                        end,
                    },
                })
            end)
        end,
    },

    {
        'mfussenegger/nvim-dap-python',
        dependencies = { 'mfussenegger/nvim-dap' },
        ft = { 'python' },
        config = function()
            local dap_py = require('dap-python')
            dap_py.setup()
            dap_py.test_runner = 'pytest'
        end,
    },
}
