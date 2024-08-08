local a = require('dotvim.util.async')

local M = {}

function M.close_dap()
    local dap = require('dap')
    dap.disconnect()
    dap.close()
    local ui = vim.F.npcall(require, 'dapui')
    if ui then
        ui.close()
    end
    local vt = vim.F.npcall(require, 'nvim-dap-virtual-text.virtual_text')
    if vt then
        vt.clear_virtual_text()
    end
end

function M.set_condition_breakpoint()
    local dap = require('dap')
    local cond = a.ui.input({ prompt = 'Breakpoint condition (var > 10):' }).await()
    dap.set_breakpoint(cond)
end

function M.set_log_point()
    local dap = require('dap')
    local log_message = a.ui.input({ prompt = 'Log point message (var = {var}):' }).await()
    dap.set_breakpoint(nil, nil, log_message)
end

function M.set_hit_count()
    local dap = require('dap')
    local hit_count = a.ui.input({ prompt = 'Hit count:' }).await()
    dap.set_breakpoint(nil, hit_count, nil)
end

M.select_breakpoint = a.wrap(function()
    local actions = {
        ['Breakpoint'] = require('dap').set_breakpoint,
        ['Condition'] = M.set_condition_breakpoint,
        ['Hit count'] = M.set_hit_count,
        ['Log message'] = M.set_log_point,
    }
    local choice = a.ui.select(vim.tbl_keys(actions), { prompt = 'Select Breakpoint Type:' }).await()
    if choice then
        actions[choice]()
    end
end)

function M.open_repl(...)
    require('dap').repl.open(...)
end

M.dap_proxy = setmetatable({}, {
    __index = function(_, key)
        return function(...)
            local dap = require('dap')
            return dap[key](...)
        end
    end,
})

function M.setup()
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

    vim.api.nvim_create_autocmd({ 'FileType' }, {
        group = vim.api.nvim_create_augroup('dotvim_dap_cmp', { clear = true }),
        pattern = { 'dap-repl' },
        callback = function()
            require('dap.ext.autocompl').attach()
        end,
    })

    local sign_define = vim.fn.sign_define
    sign_define('DapStopped', { text = '', texthl = 'DapCustomPC' })
    sign_define('DapBreakpoint', { text = '', texthl = 'DapBreakpoint' })
    sign_define('DapBreakpointCondition', { text = '', texthl = 'DapBreakpointCondition' })
    sign_define('DapBreakpointRejected', { text = '', texthl = 'DapBreakpointRejected' })
    sign_define('DapLogPoint', { text = '', texthl = 'DapLogPoint' })
end

local ui = {}

function ui.setup()
    local dapui = require('dapui')
    dapui.setup({
        icons = {
            expanded = '▾',
            collapsed = '▸',
        },
        mappings = {
            -- Use a table to apply multiple mappings
            expand = { '<CR>' },
            open = 'o',
            remove = 'd',
            edit = 'e',
            repl = 'r',
        },
        layouts = {
            {
                elements = {
                    'scopes',
                    'breakpoints',
                    'stacks',
                    'watches',
                },
                size = 40,
                position = 'left',
            },
            {
                elements = {
                    'repl',
                    'console',
                },
                size = 10,
                position = 'bottom',
            },
        },

        floating = {
            border = {},
            mappings = {
                close = { 'q', '<Esc>' },
            },
            max_height = nil, -- These can be integers or a float between 0 and 1.
            max_width = nil, -- Floats will be treated as percentage of your screen.
        },
    })

    local dap = require('dap')
    dap.listeners.after.event_initialized['dapui_config'] = function()
        dapui.open()
        vim.opt.mouse = 'n'
    end
    dap.listeners.before.event_terminated['dapui_config'] = function()
        dapui.close()
        vim.opt.mouse = ''
    end
    dap.listeners.before.event_exited['dapui_config'] = function()
        dapui.close()
        vim.opt.mouse = ''
    end
end

M.ui = ui

local virtual_text = {}

function virtual_text.setup()
    require('nvim-dap-virtual-text').setup({
        enabled = true,
        enabled_commands = true,
        highlight_changed_variables = true,
        highlight_new_as_changed = false,
        show_stop_reason = true,
        all_frames = false,
    })
end

M.virtual_text = virtual_text

return M
