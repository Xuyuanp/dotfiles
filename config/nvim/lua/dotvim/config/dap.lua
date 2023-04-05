local a = require('dotvim.util.async')

local M = {}

local function close_dap()
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

local function set_condition_breakpoint()
    local dap = require('dap')
    local cond = a.ui.input({ prompt = 'Breakpoint condition (var > 10):' }).await()
    dap.set_breakpoint(cond)
end

local function set_log_point()
    local dap = require('dap')
    local log_message = a.ui.input({ prompt = 'Log point message (var = {var}):' }).await()
    dap.set_breakpoint(nil, nil, log_message)
end

local function set_hit_count()
    local dap = require('dap')
    local hit_count = a.ui.input({ prompt = 'Hit count:' }).await()
    dap.set_breakpoint(nil, hit_count, nil)
end

local set_breakpoint = a.wrap(function()
    local actions = {
        ['Breakpoint'] = require('dap').set_breakpoint,
        ['Condition'] = set_condition_breakpoint,
        ['Hit count'] = set_hit_count,
        ['Log message'] = set_log_point,
    }
    local choice = a.ui.select(vim.tbl_keys(actions), { prompt = 'Select Breakpoint Type:' }).await()
    if choice then
        actions[choice]()
    end
end)

function M.setup()
    local sign_define = vim.fn.sign_define

    local dap = require('dap')

    local set_keymap = vim.keymap.set
    -- stylua: ignore start
    set_keymap('n', '<F5>',       dap.continue,          { remap = true, silent = true, desc = '[Dap] continue' })
    set_keymap('n', '<F6>',       dap.run_to_cursor,     { remap = true, silent = true, desc = '[Dap] run to cursor' })
    set_keymap('n', '<F9>',       close_dap,             { remap = true, silent = true, desc = '[Dap] close' })
    set_keymap('n', '<F10>',      dap.step_over,         { remap = true, silent = true, desc = '[Dap] step over' })
    set_keymap('n', '<F11>',      dap.step_into,         { remap = true, silent = true, desc = '[Dap] step into' })
    set_keymap('n', '<F12>',      dap.step_out,          { remap = true, silent = true, desc = '[Dap] step out' })
    set_keymap('n', '<leader>dr', dap.repl.open,         { remap = true, silent = true, desc = '[Dap] repl open' })
    set_keymap('n', '<leader>dl', dap.run_last,          { remap = true, silent = true, desc = '[Dap] run last' })
    set_keymap('n', '<leader>b',  dap.toggle_breakpoint, { remap = true, silent = true, desc = '[Dap] toggle breakpoint' })
    set_keymap('n', '<leader>B',  set_breakpoint,        { remap = true, silent = true, desc = '[Dap] set breakpoint' })
    -- stylua: ignore end

    vim.api.nvim_create_autocmd({ 'FileType' }, {
        group = vim.api.nvim_create_augroup('dotvim_dap_cmp', { clear = true }),
        pattern = { 'dap-repl' },
        callback = function()
            require('dap.ext.autocompl').attach()
        end,
    })

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
