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
        dependencies = {
            'nvim-neotest/nvim-nio',
            'nvim-lua/plenary.nvim',
            'rcarriga/nvim-dap-ui',
            'theHamsta/nvim-dap-virtual-text',
            'nvim-telescope/telescope-dap.nvim',
            { 'jay-babu/mason-nvim-dap.nvim', version = 'v2' },
        },
        cmd = { 'DapContinue' },
        keys = {
            -- stylua: ignore start
            { '<F5>',       require('dotvim.config.dap').dap_proxy.continue,          mode = 'n', desc = '[Dap] continue' },
            { '<F6>',       require('dotvim.config.dap').dap_proxy.run_to_cursor,     mode = 'n', desc = '[Dap] run to cursor' },
            { '<F10>',      require('dotvim.config.dap').dap_proxy.step_over,         mode = 'n', desc = '[Dap] step over' },
            { '<F11>',      require('dotvim.config.dap').dap_proxy.step_into,         mode = 'n', desc = '[Dap] step into' },
            { '<F12>',      require('dotvim.config.dap').dap_proxy.step_out,          mode = 'n', desc = '[Dap] step out' },
            { '<leader>dl', require('dotvim.config.dap').dap_proxy.run_last,          mode = 'n', desc = '[Dap] run last' },
            { '<leader>b',  require('dotvim.config.dap').dap_proxy.toggle_breakpoint, mode = 'n', desc = '[Dap] toggle breakpoint', },
            { '<leader>dr', require('dotvim.config.dap').open_repl,                   mode = 'n', desc = '[Dap] repl open' },
            { '<F9>',       require('dotvim.config.dap').close_dap,                   mode = 'n', desc = '[Dap] close' },
            { '<leader>B',  require('dotvim.config.dap').select_breakpoint,           mode = 'n', desc = '[Dap] select breakpoint' },
            -- stylua: ignore end
        },
        config = function()
            require('dotvim.config.dap').setup()
            require('dotvim.config.dap').ui.setup()
            require('dotvim.config.dap').virtual_text.setup()
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
