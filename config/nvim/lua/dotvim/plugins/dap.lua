return {

    {
        'mfussenegger/nvim-dap',
        cmd = { 'DapContinue' },
        dependencies = {
            'jay-babu/mason-nvim-dap.nvim',
            { 'theHamsta/nvim-dap-virtual-text', opts = {} },
            {
                'rcarriga/nvim-dap-ui',
                dependencies = { 'nvim-neotest/nvim-nio' },
                opts = {},
            },
        },
        keys = function()
            local cfg = require('dotvim.config.dap')
            return {
                -- stylua: ignore start
                { '<F5>',       cfg.proxy.continue,          desc = 'Run/Continue' },
                { '<leader>dc', cfg.proxy.continue,          desc = 'Run/Continue <F5>' },
                { '<F6>',       cfg.proxy.run_to_cursor,     desc = 'Run to cursor' },
                { '<leader>dC', cfg.proxy.run_to_cursor,     desc = 'Run to cursor <F6>' },
                { '<F10>',      cfg.proxy.step_over,         desc = 'Step over' },
                { '<leader>dO', cfg.proxy.step_over,         desc = 'Step over <F10>' },
                { '<F11>',      cfg.proxy.step_into,         desc = 'Step into' },
                { '<leader>di', cfg.proxy.step_into,         desc = 'Step into <F11>' },
                { '<F12>',      cfg.proxy.step_out,          desc = 'Step out' },
                { '<leader>do', cfg.proxy.step_out,          desc = 'Step out <F12>' },
                { '<leader>dj', cfg.proxy.down,              desc = 'Down' },
                { '<leader>dk', cfg.proxy.up,                desc = 'Up' },
                { '<leader>dl', cfg.proxy.run_last,          desc = 'Run last' },
                { '<leader>db', cfg.proxy.toggle_breakpoint, desc = 'Toggle breakpoint' },
                { '<leader>b',  cfg.proxy.toggle_breakpoint, desc = 'Toggle breakpoint' },
                { '<leader>dB', cfg.select_breakpoint,       desc = 'Select breakpoint type' },
                { '<leader>dL', cfg.list_breakpoints,        desc = 'List breakpoints' },
                { '<leader>dr', cfg.open_repl,               desc = 'Open repl' },
                { '<F9>',       cfg.terminate,               desc = 'Terminate' },
                { '<leader>dt', cfg.terminate,               desc = 'Terminate <F9>' },
                { '<leader>dh', cfg.widget_hover,            desc = 'Widget hover' },
                -- stylua: ignore end
            }
        end,
        config = function()
            require('dotvim.config.dap').setup()
        end,
        specs = {
            {
                'folke/which-key.nvim',
                optional = true,
                opts_extend = { 'spec' },
                opts = {
                    spec = {
                        { '<leader>d', group = 'debug', icon = { icon = '', color = 'yellow' } },
                    },
                },
            },
        },
    },

    {
        'jay-babu/mason-nvim-dap.nvim',
        dependencies = { 'williamboman/mason.nvim' },
        cmd = { 'DapInstall', 'DapUninstall' },
        opts = {
            handlers = {
                function(config)
                    local options = config.adapters.options or {}
                    options.initialize_timeout_sec = 60
                    config.adapters.options = options

                    require('mason-nvim-dap').default_setup(config)
                end,
            },
        },
    },

    {
        'mfussenegger/nvim-dap-python',
        dependencies = {
            'mfussenegger/nvim-dap',
            {
                'jay-babu/mason-nvim-dap.nvim',
                optional = true,
                opts = {
                    automatic_setup = {
                        filetypes = {
                            python = false,
                        },
                    },
                },
            },
        },
        ft = { 'python' },
        config = function()
            local dap_py = require('dap-python')
            dap_py.setup()
            dap_py.test_runner = 'pytest'
        end,
    },
}
