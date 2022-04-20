local yaml = require('lyaml')

local source = {}

function source.new()
    local self = setmetatable({}, { __index = source })
    return self
end

local fnamemodify = vim.fn.fnamemodify

local function upper_dir(path)
    return fnamemodify(path, ':h')
end

local function load_values(bufnr)
    local path = vim.api.nvim_buf_get_name(bufnr)

    while path ~= '/' do
        path = upper_dir(path)
        if vim.endswith(path, 'templates') then
            path = upper_dir(path)
            local chart_file = path .. '/Chart.yaml'
            if vim.fn.filereadable(chart_file) then
                local values_file = path .. '/values.yaml'
                local f = assert(io.open(values_file, 'rb'))
                local yaml_data = f:read('*all')
                f:close()
                return yaml.load(yaml_data)
            end
        end
    end

    assert(false, 'unreachable')
end

local metas = setmetatable({}, {
    __index = function(t, bufnr)
        t[bufnr] = { values = load_values(bufnr) }
        return t[bufnr]
    end,
})

function source:get_trigger_characters()
    return { '.' }
end

function source:complete(params, callback)
    local ctx = params.context

    local meta = metas[ctx.bufnr]
    assert(meta)

    if not string.find(ctx.cursor_before_line, '{{') then
        callback({})
        return
    end

    print(ctx.cursor_before_line)
    print(ctx.cursor_line)
    print(ctx.cursor_after_line)

    if vim.endswith(ctx.cursor_before_line, ' .') then
        callback({
            { label = 'Values' },
            { label = 'Chart' },
        })
    elseif vim.endswith(ctx.cursor_before_line, ' .Values.') then
        print('complete Values')
        local items = {}
        for key, _ in pairs(meta.values) do
            table.insert(items, { label = key })
        end
        callback(items)
    else
        vim.defer_fn(function()
            callback({
                items = {
                    { label = 'helm' },
                },
                isIncomplete = false,
            })
        end, 100)
    end
end

return source
