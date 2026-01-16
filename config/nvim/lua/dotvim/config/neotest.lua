local a = require('dotvim.util.async')

local M = {}

local function run_file()
    require('neotest').run.run(vim.fn.expand('%'))
end

local function run_nearest()
    require('neotest').run.run()
end

local function debug_nearest()
    require('neotest').run.run({ strategy = 'dap', suite = false })
end

local function toggle_summary()
    require('neotest').summary.toggle()
end

local function toggle_output()
    require('neotest').output.open({ enter = true })
end

local test_menu = a.wrap(function()
    local actions = {
        ['Run file'] = run_file,
        ['Run nearest'] = run_nearest,
        ['Debug nearest'] = debug_nearest,
        ['Toggle summary'] = toggle_summary,
        ['Show output'] = toggle_output,
    }

    local choices = vim.tbl_keys(actions)
    table.sort(choices)
    local choice = a.ui.select(choices, { prompt = 'Select test action:' }).await()
    if not choice then
        return
    end
    vim.schedule(function()
        actions[choice]()
    end)
end)

function M.setup(opts)
    -- get neotest namespace (api call creates or returns namespace)
    local neotest_ns = vim.api.nvim_create_namespace('neotest')
    vim.diagnostic.config({
        virtual_text = {
            format = function(diagnostic)
                local message = diagnostic.message:gsub('\n', ' '):gsub('\t', ' '):gsub('%s+', ' '):gsub('^%s+', '')
                return message
            end,
        },
    }, neotest_ns)

    vim.api.nvim_create_autocmd('FileType', {
        pattern = 'neotest-*',
        group = vim.api.nvim_create_augroup('dotvim.neotest', { clear = true }),
        callback = function()
            vim.keymap.set('n', 'q', '<cmd>close<cr>', { buffer = true, desc = 'Close window' })
        end,
    })

    local done = false

    vim.keymap.set({ 'n', 'i' }, '<leader>t', function()
        if not done then
            require('neotest').setup(opts)
            done = true
        end
        test_menu()
    end, {
        remap = true,
        silent = true,
        desc = '[Neotest] menu',
    })
end

return M
