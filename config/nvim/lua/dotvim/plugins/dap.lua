local vim = vim

return {
    {
        'mfussenegger/nvim-dap',
        name = 'dap',
        lazy = true,
        dependencies = {
            'plenary',
            'rcarriga/nvim-dap-ui',
            {
                'theHamsta/nvim-dap-virtual-text',
                dependencies = {
                    'nvim-treesitter/nvim-treesitter',
                },
            },
        },
        config = function()
            require('dotvim.dap').setup()
            require('dotvim.dap').ui.setup()
            require('dotvim.dap').virtual_text.setup()
        end,
    },

    {
        'mfussenegger/nvim-dap-python',
        dependencies = { 'dap' },
        ft = { 'python' },
        config = function()
            local dap_py = require('dap-python')
            dap_py.setup('~/.pyenv/versions/debugpy/bin/python')
            dap_py.test_runner = 'pytest'
        end,
    },

    {
        'nvim-telescope/telescope-dap.nvim',
        dependencies = { 'dap', 'telescope' },
        cmd = { 'Telescope' },
        config = function()
            require('telescope').load_extension('dap')
        end,
    },
}
