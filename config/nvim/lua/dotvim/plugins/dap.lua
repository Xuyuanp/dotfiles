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
            'plenary',
            'rcarriga/nvim-dap-ui',
            'theHamsta/nvim-dap-virtual-text',
            'nvim-telescope/telescope-dap.nvim',
            'jay-babu/mason-nvim-dap.nvim',
        },
        config = function()
            require('dotvim.config.dap').setup()
            require('dotvim.config.dap').ui.setup()
            require('dotvim.config.dap').virtual_text.setup()

            -- required
            vim.schedule(function()
                require('mason-nvim-dap').setup({
                    automatic_install = false,
                    automatic_setup = {
                        filetypes = {
                            python = false,
                            rust = false,
                        },
                    },
                })
                require('mason-nvim-dap').setup_handlers({
                    function(source_name)
                        require('mason-nvim-dap.automatic_setup')(source_name)
                    end,
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
            dap_py.setup('~/.pyenv/versions/debugpy/bin/python')
            dap_py.test_runner = 'pytest'
        end,
    },
}
