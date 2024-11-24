local api = vim.api
local vfn = vim.fn

local M = {}

M.fzf_run = vfn['fzf#run']
local _fzf_wrap = vfn['fzf#wrap']
M.fzf_wrap = function(name, spec, fullscreen)
    local wrapped = _fzf_wrap(name, spec, fullscreen or false)

    wrapped['sink*'] = spec['sink*']
    wrapped.sink = spec['sink']

    return wrapped
end

local border_symbols = {
    vertical = '┃',
    horizontal = '━',
    fill = ' ',
    corner = {
        topleft = '┏',
        topright = '┓',
        bottomleft = '┗',
        bottomright = '┛',
    },
}

function border_symbols:draw(width, height)
    local border_lines = {
        table.concat({
            self.corner.topleft,
            string.rep(self.horizontal, width),
            self.corner.topright,
        }),
    }
    local middle_line = table.concat({
        self.vertical,
        string.rep(self.fill, width),
        self.vertical,
    })
    for _ = 1, height do
        table.insert(border_lines, middle_line)
    end
    table.insert(
        border_lines,
        table.concat({
            self.corner.bottomleft,
            string.rep(self.horizontal, width),
            self.corner.bottomright,
        })
    )

    return border_lines
end

function M.floating_window(bufnr)
    local winnr_bak = vfn.winnr()
    local altwinnr_bak = vfn.winnr('#')

    local width, height = vim.o.columns, vim.o.lines

    local win_width = math.ceil(width * 0.8) - 4
    local win_height = math.ceil(height * 0.8)
    local row = math.ceil((height - win_height) / 2 - 1)
    local col = math.ceil((width - win_width) / 2)

    -- border
    local border_opts = {
        style = 'minimal',
        relative = 'editor',
        width = win_width + 2,
        height = win_height + 2,
        row = row - 1,
        col = col - 1,
    }

    local border_bufnr = api.nvim_create_buf(false, true)
    local border_lines = border_symbols:draw(win_width, win_height)
    api.nvim_buf_set_lines(border_bufnr, 0, -1, false, border_lines)
    local border_winnr = api.nvim_open_win(border_bufnr, true, border_opts)
    api.nvim_set_option_value('winhl', 'NormalFloat:', { win = border_winnr })
    api.nvim_set_option_value('winblend', 0, { win = border_winnr })

    -- content
    local win_opts = {
        style = 'minimal',
        relative = 'editor',
        width = win_width,
        height = win_height,
        row = row,
        col = col,
    }
    local winnr = api.nvim_open_win(bufnr, true, win_opts)

    api.nvim_create_autocmd({ 'BufWipeout' }, {
        buffer = bufnr,
        callback = function()
            vim.cmd(string.format([[silent bwipeout! %d]], border_bufnr))
        end,
    })
    api.nvim_create_autocmd({ 'WinClosed' }, {
        buffer = bufnr,
        callback = function()
            vim.cmd(string.format([[%dwincmd w]], altwinnr_bak))
            vim.cmd(string.format([[%dwincmd w]], winnr_bak))
        end,
    })

    local key_opts = { nowait = true, noremap = false, silent = false, buffer = bufnr }
    vim.keymap.set('n', 'q', ':q<CR>', key_opts)
    vim.keymap.set('n', '<ESC><ESC>', ':q<CR>', key_opts)

    return winnr
end

function M.async()
    return require('dotvim.util.async')
end

function M.wrap_func_before(old, new)
    if not new then
        return old
    end
    if not old then
        return new
    end
    return function(...)
        new(...)
        old(...)
    end
end

function M.wrap_func_after(old, new)
    if not new then
        return old
    end
    if not old then
        return new
    end
    return function(...)
        old(...)
        new(...)
    end
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

function M.hijack_notify()
    local notify = vim.notify
    vim.notify = setmetatable({}, {
        __call = function(_, ...)
            notify(...)
        end,
        __index = function(obj, level)
            local f = function(msg, opts)
                notify(msg, level, opts)
            end
            rawset(obj, level, f)
            return f
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
