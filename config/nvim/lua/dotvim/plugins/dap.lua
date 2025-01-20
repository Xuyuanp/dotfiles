return {

    {
        'mfussenegger/nvim-dap',
        cmd = { 'DapContinue' },
        dependencies = {
            'jay-babu/mason-nvim-dap.nvim',
            { 'theHamsta/nvim-dap-virtual-text', opts = {} },
            {
                'rcarriga/nvim-dap-ui',
                dependencies = {
                    'nvim-neotest/nvim-nio',
                },
                opts = {},
            },
        },
        keys = function()
            local cfg = require('dotvim.config.dap')
            return {
                -- stylua: ignore start
                { '<F5>',       cfg.dap_proxy.continue,          desc = 'Run/Continue' },
                { '<leader>dc', cfg.dap_proxy.continue,          desc = 'Run/Continue <F5>' },
                { '<F6>',       cfg.dap_proxy.run_to_cursor,     desc = 'Run to cursor' },
                { '<leader>dC', cfg.dap_proxy.run_to_cursor,     desc = 'Run to cursor <F6>' },
                { '<F10>',      cfg.dap_proxy.step_over,         desc = 'Step over' },
                { '<leader>dO', cfg.dap_proxy.step_over,         desc = 'Step over <F10>' },
                { '<F11>',      cfg.dap_proxy.step_into,         desc = 'Step into' },
                { '<leader>di', cfg.dap_proxy.step_into,         desc = 'Step into <F11>' },
                { '<F12>',      cfg.dap_proxy.step_out,          desc = 'Step out' },
                { '<leader>do', cfg.dap_proxy.step_out,          desc = 'Step out <F12>' },
                { '<leader>dj', cfg.dap_proxy.down,              desc = 'Down' },
                { '<leader>dk', cfg.dap_proxy.up,                desc = 'Up' },
                { '<leader>dl', cfg.dap_proxy.run_last,          desc = 'Run last' },
                { '<leader>db', cfg.dap_proxy.toggle_breakpoint, desc = 'Toggle breakpoint' },
                { '<leader>b',  cfg.dap_proxy.toggle_breakpoint, desc = 'Toggle breakpoint' },
                { '<leader>dB', cfg.select_breakpoint,           desc = 'Select breakpoint type' },
                { '<leader>dr', cfg.open_repl,                   desc = 'Open repl' },
                { '<F9>',       cfg.terminate,                   desc = 'Terminate' },
                { '<leader>dt', cfg.terminate,                   desc = 'Terminate <F9>' },
                { '<leader>dw', cfg.widget_hover,                desc = 'Widget' },
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
