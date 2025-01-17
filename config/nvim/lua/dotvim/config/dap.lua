local a = require('dotvim.util.async')

local M = {}

function M.terminate()
    local dap = require('dap')
    dap.terminate()
end

function M.widget_hover()
    require('dap.ui.widgets').hover()
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
    local group_id = vim.api.nvim_create_augroup('dotvim_dap', { clear = true })
    vim.api.nvim_create_autocmd({ 'FileType' }, {
        group = group_id,
        pattern = { 'dap-repl' },
        callback = function()
            require('dap.ext.autocompl').attach()
        end,
    })
    vim.api.nvim_create_autocmd({ 'FileType' }, {
        group = group_id,
        pattern = { 'dap-float' },
        callback = function()
            vim.keymap.set('n', 'q', '<cmd>q<cr>', { buffer = true })
        end,
    })
    vim.api.nvim_create_autocmd({ 'FileType' }, {
        group = group_id,
        pattern = { 'dap-repl' },
        callback = function(args)
            vim.api.nvim_create_autocmd('BufWinEnter', {
                buffer = args.buf,
                command = 'startinsert',
            })
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

function ui.setup(opts)
    local dapui = require('dapui')
    dapui.setup(opts)

    local dap = require('dap')
    dap.listeners.before.attach.dapui_config = function()
        dapui.open()
    end
    dap.listeners.before.launch.dapui_config = function()
        dapui.open()
    end
    dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
    end
    dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
    end
end

M.ui = ui

return M
