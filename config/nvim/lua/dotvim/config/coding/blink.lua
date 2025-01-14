local function append_default(default, names)
    names = vim.islist(names) and names or { names }
    if type(default) == 'function' then
        return function(...)
            local original = default(...)
            return vim.list_extend(original, names)
        end
    else
        local original = vim.deepcopy(default)
        return vim.list_extend(original, names)
    end
end

local function transform_items_for_kind(kind_idx, default)
    return function(o, items)
        if default then
            items = default(o, items)
        end
        for _, item in ipairs(items) do
            item.kind = kind_idx
        end
        return items
    end
end

local function overwrite_default_capabilities()
    local default_capabilities = require('dotvim.config.lsp.capabilities')
    local blink_capabilities = require('blink.cmp').get_lsp_capabilities()
    if not vim.deep_equal(default_capabilities, blink_capabilities) then
        vim.notify_once('Blink capabilities are different from default capabilities', vim.log.levels.WARN)

        local source = 'return ' .. vim.inspect(blink_capabilities, { indent = '    ' })
        local config_path = vim.fn.stdpath('config')
        config_path = type(config_path) == 'string' and config_path or config_path[1]
        local fname = vim.fs.joinpath(config_path, 'lua/dotvim/config/lsp/capabilities.lua')
        vim.fn.writefile(vim.split(source, '\n'), fname)
    end
end

local M = {}

function M.setup(opts)
    opts = opts or {}
    local ft_providers = {}
    for name, provider in pairs(opts.sources.providers) do
        if provider.kind then
            local CompletionItemKind = require('blink.cmp.types').CompletionItemKind
            local kind_idx = #CompletionItemKind + 1
            CompletionItemKind[kind_idx] = provider.kind
            CompletionItemKind[provider.kind] = kind_idx
            provider.transform_items = transform_items_for_kind(kind_idx, provider.transform_items)
            provider.kind = nil
        end

        for _, ft in ipairs(provider.filetypes or {}) do
            ft_providers[ft] = ft_providers[ft] or {}
            table.insert(ft_providers[ft], name)
        end
        provider.filetypes = nil
    end

    opts.sources.per_filetype = opts.sources.per_filetype or {}
    for ft, names in pairs(ft_providers) do
        local old = opts.sources.per_filetype[ft]
        if not old then
            opts.sources.per_filetype[ft] = append_default(opts.sources.default, names)
        elseif #old > 0 then
            opts.sources.per_filetype[ft] = append_default(old, names)
        end
    end
    require('blink.cmp').setup(opts)

    overwrite_default_capabilities()
end

return M
