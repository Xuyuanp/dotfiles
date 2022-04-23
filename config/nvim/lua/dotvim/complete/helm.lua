local a = require('dotvim.util.async')
local uv = a.uv()
local api = a.api

local singleflight = require('dotvim.util.singleflight')

local yaml = require('lyaml')
local notify = vim.F.npcall(require, 'notify') or vim.notify

local types_lsp = require('cmp.types.lsp')
local ItemKind = types_lsp.CompletionItemKind

local Chart = {}

function Chart.new(opt)
    local chart = setmetatable(opt, { __index = Chart })
    chart:init()
    return chart
end

function Chart:init()
    self.singleflight = singleflight.new()
    self:load()
end

function Chart:watch_file(path, callback)
    local watcher = uv.new_fs_event()
    watcher:start(path, {}, function(err, _filename, events)
        if err then
            notify(string.format('watching file %s failed: %s', path, tostring(err)), 'ERROR')
            watcher:stop()
            return
        end
        if events.change then
            self.singleflight:run(path, function()
                callback(path)
            end)
        end
    end)
end

local function load_yaml(path)
    local err, data = uv.read_file(path)
    assert(not err, err)

    local ok, res_or_err = pcall(yaml.load, data)
    if not ok then
        notify(tostring(res_or_err), 'WARN', {
            title = 'load yaml ' .. path .. ' failed',
        })
        return
    end
    return res_or_err
end

function Chart:load_values(path)
    local res = load_yaml(path)
    if res then
        self.values = res
    end
end

function Chart:load_meta(path)
    local res = load_yaml(path)
    if res then
        self.meta = res
    end
end

function Chart:load_helpers(path)
    local err, data = uv.read_file(path)
    assert(not err, err)
    local helpers = {}
    for help in string.gmatch(data, [[{{%-?%s+define%s+([^}]*)%s+%-?}}]]) do
        table.insert(helpers, help)
    end
    self.helpers = helpers
end

function Chart:load()
    local helpers_file = self.root .. '/templates/_helpers.tpl'
    local chart_file = self.root .. '/Chart.yaml'
    local values_file = self.root .. '/values.yaml'

    self:load_meta(chart_file)
    self:load_values(values_file)
    self:load_helpers(helpers_file)

    if self.watch then
        self:watch_file(chart_file, function(filename)
            notify('reloading file ' .. filename)
            self:load_meta(filename)
        end)
        self:watch_file(values_file, function(filename)
            notify('reloading file ' .. filename)
            self:load_values(filename)
        end)
        self:watch_file(helpers_file, function(filename)
            notify('reloading file ' .. filename)
            self:load_helpers(filename)
        end)
    end
end

function Chart:complete(prefix)
    local obj

    if vim.startswith(prefix, '.Values.') or vim.startswith(prefix, '$.Values.') then
        obj = self.values
    elseif vim.startswith(prefix, '.Chart.') or vim.startswith(prefix, '$.Chart.') then
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
                t[root] = Chart.new({
                    root = root,
                    watch = true,
                })
                return t[root]
            end,
        }),
    }, { __index = source })
    return self
end

function source:get_trigger_characters()
    return { '.', ' ' }
end

local function get_prefixes(str)
    local fields = vim.split(str, '%s')
    return fields
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

    local prefixes = get_prefixes(ctx.cursor_before_line)
    local prefix = prefixes[#prefixes]

    if prefix == '' then
        if prefixes[#prefixes - 1] == 'include' or prefixes[#prefixes - 1] == 'template' then
            local items = {}
            for _, key in ipairs(chart.helpers) do
                table.insert(items, {
                    label = key,
                    kind = ItemKind.Reference,
                })
            end
            callback(items)
            return
        end
        callback({
            { label = 'include', kind = ItemKind.Keyword },
            { label = 'template', kind = ItemKind.Keyword },
        })
        return
    end

    if prefix == '.' or prefix == '$.' then
        callback({
            { label = 'Values', kind = ItemKind.Module },
            { label = 'Chart', kind = ItemKind.Module },
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
                    kind = ItemKind.Field,
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
