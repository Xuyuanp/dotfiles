local a = require('dotvim.util.async')
local uv = a.uv()
local api = a.api

local yaml = require('lyaml')

local types_lsp = require('cmp.types.lsp')

local Chart = {}

function Chart.new(root)
    local chart = setmetatable({ root = root }, { __index = Chart })
    chart:load()
    return chart
end

local function load_yaml(path)
    local err, data = uv.read_file(path)
    assert(not err, err)
    return yaml.load(data)
end

function Chart:load()
    -- local helpers_file = self.root .. '/templates/_helpers.tpl'
    local chart_file = self.root .. '/Chart.yaml'
    local values_file = self.root .. '/values.yaml'

    self.values = load_yaml(values_file)
    self.meta = load_yaml(chart_file)
end

function Chart:complete(prefix)
    local obj

    if vim.startswith(prefix, '.Values.') then
        obj = self.values
    elseif vim.startswith(prefix, '.Chart.') then
        obj = self.meta
    else
        return
    end

    local keys = vim.split(prefix, '.', { plain = true })

    for i = 3, #keys - 1 do
        obj = obj[keys[i]]
        if not obj then
            return {}
        end
    end

    return obj
end

local fnamemodify = vim.fn.fnamemodify

local function upper_dir(path)
    return fnamemodify(path, ':h')
end

local function find_root_path(path)
    while path ~= '/' do
        path = upper_dir(path)
        if vim.endswith(path, 'templates') then
            return upper_dir(path)
        end
    end
end

local source = {}

function source.new()
    local self = setmetatable({
        charts = setmetatable({}, {
            __index = function(t, root)
                t[root] = Chart.new(root)
                return t[root]
            end,
        }),
    }, { __index = source })
    return self
end

function source:get_trigger_characters()
    return { '.' }
end

local function get_prefix(str)
    local fields = vim.split(str, ' ', { plain = true })
    return fields[#fields]
end

source.complete = a.wrap(function(self, params, callback)
    local ctx = params.context

    if not string.find(ctx.cursor_before_line, '{{') then
        callback({})
        return
    end

    local path = api.nvim_buf_get_name(ctx.bufnr)
    local root = find_root_path(path)
    if not root then
        callback({})
        return
    end

    local chart = self.charts[root]

    local prefix = get_prefix(ctx.cursor_before_line)

    if prefix == '.' then
        callback({
            { label = 'Values', kind = types_lsp.CompletionItemKind.Module },
            { label = 'Chart', kind = types_lsp.CompletionItemKind.Module },
        })
        return
    end

    local obj = chart:complete(prefix)

    if type(obj) == 'table' then
        if not vim.tbl_islist(obj) then
            local items = {}
            for key, value in pairs(obj) do
                table.insert(items, {
                    label = key,
                    kind = types_lsp.CompletionItemKind.Field,
                    documentation = {
                        value = (function()
                            if type(value) == 'table' then
                                local markdown = string.format('```yaml\n%s\n```', yaml.dump({ value }))
                                return markdown
                            end
                            return tostring(value)
                        end)(),
                        kind = types_lsp.MarkupKind.Markdown,
                    },
                })
            end
            callback(items)
            return
        end
    end

    callback({})
end)

return {
    new = source.new,
}
