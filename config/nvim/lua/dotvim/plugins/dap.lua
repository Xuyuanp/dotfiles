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
        keys = function()
            local cfg = require('dotvim.config.dap')
            return {
                -- stylua: ignore start
                { '<F5>',       cfg.dap_proxy.continue,          desc = '[Dap] continue' },
                { '<F6>',       cfg.dap_proxy.run_to_cursor,     desc = '[Dap] run to cursor' },
                { '<F10>',      cfg.dap_proxy.step_over,         desc = '[Dap] step over' },
                { '<F11>',      cfg.dap_proxy.step_into,         desc = '[Dap] step into' },
                { '<F12>',      cfg.dap_proxy.step_out,          desc = '[Dap] step out' },
                { '<leader>dl', cfg.dap_proxy.run_last,          desc = '[Dap] run last' },
                { '<leader>b',  cfg.dap_proxy.toggle_breakpoint, desc = '[Dap] toggle breakpoint', },
                { '<leader>dr', cfg.open_repl,                   desc = '[Dap] repl open' },
                { '<F9>',       cfg.close_dap,                   desc = '[Dap] close' },
                { '<leader>B',  cfg.select_breakpoint,           desc = '[Dap] select breakpoint' },
                -- stylua: ignore end
            }
        end,
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
