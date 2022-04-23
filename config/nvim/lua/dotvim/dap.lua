local M = {}

local function setup_go()
    local dap = require('dap')
    local pjob = require('plenary.job')
    dap.adapters.go = function(callback, _config)
        local port = 38697
        local job_desc = {
            command = 'dlv',
            args = {
                'dap',
                '-l',
                '127.0.0.1:' .. port,
                '--check-go-version=false',
            },
            on_stdout = function(err, chunk)
                assert(not err, err)
                if chunk then
                    vim.schedule(function()
                        require('dap.repl').append(chunk)
                    end)
                end
            end,
        }
        pjob:new(job_desc):start()

        vim.defer_fn(function()
            callback({
                type = 'server',
                host = '127.0.0.1',
                port = port,
            })
        end, 100)
    end

    dap.configurations.go = {
        {
            type = 'go',
            name = 'Debug',
            request = 'launch',
            program = '${file}',
        },
        {
            type = 'go',
            name = 'Debug test',
            request = 'test',
            mode = 'test',
            program = '${file}',
        },
        {
            type = 'go',
            name = 'Debug test (go.mod)',
            request = 'launch',
            mode = 'test',
            program = './${relativeFileDirname}',
        },
    }
end

function M.setup()
    setup_go()

    local sign_define = vim.fn.sign_define

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

    local dap = require('dap')

    local km_opts = { noremap = false, silent = true }

    local set_keymap = vim.keymap.set
    set_keymap('n', '<F5>', dap.continue, km_opts)
    set_keymap('n', '<F6>', dap.run_to_cursor, km_opts)
    set_keymap('n', '<F9>', close_dap, km_opts)
    set_keymap('n', '<F10>', dap.step_over, km_opts)
    set_keymap('n', '<F11>', dap.step_into, km_opts)
    set_keymap('n', '<F12>', dap.step_out, km_opts)
    set_keymap('n', '<leader>b', dap.toggle_breakpoint, km_opts)
    set_keymap('n', '<leader>dr', dap.repl.open, km_opts)
    set_keymap('n', '<leader>dl', dap.run_last, km_opts)
    set_keymap('n', '<leader>B', "<cmd>lua require('dap').set_breakpoint(vim.fn.input('Breakpoint condition: '))<CR>", km_opts)
    set_keymap('n', '<leader>lp', "<cmd>lua require('dap').set_breakpoint(nil, nil, vim.fn.input('Log point message: '))<CR>", km_opts)

    vim.api.nvim_create_autocmd({ 'FileType' }, {
        group = vim.api.nvim_create_augroup('dotvim_dap_cmp', { clear = true }),
        pattern = { 'dap-repl' },
        callback = function()
            require('dap.ext.autocompl').attach()
        end,
    })

    require('dotvim.colors').add_highlight('DapCustomPC', { bg = '#928374' })
    sign_define('DapStopped', {
        text = '',
        texthl = 'GreenSign',
        linehl = 'DapCustomPC',
    })
    sign_define('DapBreakpoint', { text = '', texthl = 'RedSign' })
    sign_define('DapLogPoint', { text = 'ﰉ', texthl = 'YellowSign' })
    sign_define('DapBreakpointRejected', { text = '' })
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
        sidebar = {
            elements = {
                -- You can change the order of elements in the sidebar
                'scopes',
                'breakpoints',
                'stacks',
                'watches',
            },
            size = 40,
            position = 'left', -- Can be "left" or "right"
        },
        tray = {
            elements = {
                'repl',
            },
            size = 10,
            position = 'top', -- Can be "bottom" or "top"
        },
        floating = {
            max_height = nil, -- These can be integers or a float between 0 and 1.
            max_width = nil, -- Floats will be treated as percentage of your screen.
        },
    })

    local dap = require('dap')
    dap.listeners.after.event_initialized['dapui_config'] = function()
        dapui.open()
    end
    dap.listeners.before.event_terminated['dapui_config'] = function()
        dapui.close()
    end
    dap.listeners.before.event_exited['dapui_config'] = function()
        dapui.close()
    end

    vim.api.nvim_create_autocmd({ 'ColorScheme' }, {
        group = vim.api.nvim_create_augroup('dotvim_dap_ui', { clear = true }),
        desc = 'Auto setup highlights of dap ui',
        pattern = { '*' },
        callback = function()
            require('dapui.config.highlights').setup()
        end,
    })
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
