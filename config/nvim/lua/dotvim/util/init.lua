local api = vim.api
local vfn = vim.fn

local M = {}

M.fzf_run = function(...)
    return vfn['fzf#run'](...)
end

M.fzf_wrap = function(name, spec, fullscreen)
    local wrapped = vim.fn['fzf#wrap'](name, spec, fullscreen or false)

    wrapped['sink*'] = spec['sink*']
    wrapped.sink = spec['sink']

    return wrapped
end

function M.open_floating_window()
    local function resize()
        local width, height = vim.o.columns, vim.o.lines

        local win_width = math.ceil(width * 0.8) - 4
        local win_height = math.ceil(height * 0.8)
        local row = math.ceil((height - win_height) / 2 - 1)
        local col = math.ceil((width - win_width) / 2)

        return win_width, win_height, row, col
    end

    local win_width, win_height, row, col = resize()

    -- content
    local win_opts = {
        style = 'minimal',
        relative = 'editor',
        width = win_width,
        height = win_height,
        row = row,
        col = col,
    }
    local bufnr = api.nvim_create_buf(false, true)
    local winnr = api.nvim_open_win(bufnr, true, win_opts)

    local auto_resize_id = api.nvim_create_autocmd('WinResized', {
        callback = function()
            win_width, win_height, row, col = resize()
            api.nvim_win_set_config(winnr, {
                relative = 'editor',
                width = win_width,
                height = win_height,
                row = row,
                col = col,
            })
        end,
    })

    api.nvim_create_autocmd({ 'WinClosed' }, {
        pattern = '' .. winnr,
        once = true,
        callback = function()
            api.nvim_del_autocmd(auto_resize_id)
        end,
    })

    local key_opts = { nowait = true, noremap = false, silent = false, buffer = bufnr }
    vim.keymap.set('n', 'q', ':q<CR>', key_opts)
    vim.keymap.set('n', '<ESC><ESC>', ':q<CR>', key_opts)

    return winnr, bufnr
end

function M.async()
    return require('dotvim.util.async')
end

function M.lazy_require(modname)
    local m = {}

    return setmetatable(m, {
        __index = function(_, key)
            return function(...)
                require(modname)[key](...)
            end
        end,
    })
end

---@generic T
---@param fn fun(key: string): T
---@return table<string, T>
function M.new_cache_table(fn)
    return setmetatable({}, {
        __index = function(obj, key)
            local value = fn(key)
            rawset(obj, key, value)
            return value
        end,
        __newindex = function()
            error('cache table is read-only')
        end,
    })
end

return M
