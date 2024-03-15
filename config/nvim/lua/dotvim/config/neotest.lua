local a = require('dotvim.util.async')

local M = {}

local function run_file()
    vim.schedule(function()
        require('neotest').run.run(vim.fn.expand('%'))
    end)
end

local function run_nearest()
    vim.schedule(function()
        require('neotest').run.run()
    end)
end

local function debug_nearest()
    vim.schedule(function()
        require('neotest').run.run({ strategy = 'dap', suite = false })
    end)
end

local function toggle_summary()
    require('neotest').summary.toggle()
end

local function toggle_output()
    vim.schedule(function()
        require('neotest').output.open({ enter = true })
    end)
end

local test_menu = a.wrap(function()
    local actions = {
        ['Run file'] = run_file,
        ['Run nearest'] = run_nearest,
        ['Debug nearest'] = debug_nearest,
        ['Toggle summary'] = toggle_summary,
        ['Show output'] = toggle_output,
    }

    local choice = a.ui.select(vim.tbl_keys(actions), { prompt = 'Select test action:' }).await()
    if choice then
        actions[choice]()
    end
end)

function M.setup()
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

    vim.keymap.set({ 'n', 'i' }, '<A-t>', test_menu, {
        remap = true,
        silent = true,
        desc = '[Neotest] menu',
    })
end

return M
