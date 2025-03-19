local buf = {}

local function with_default_opts(f, default, n)
    n = n or 1
    default = default or {}
    return function(...)
        local params = { ... }
        local opts = params[n] or {}
        local default_opts = type(default) == 'function' and default() or default
        params[n] = vim.tbl_deep_extend('force', default_opts, opts)
        return f(unpack(params, 1, n))
    end
end

local function floating_opts()
    local max_width = math.ceil(vim.o.columns * 0.8) - 4
    local width = math.min(80, max_width)
    local default = {
        width = width,
        max_width = max_width,
        title_pos = 'center',
    }
    return default
end

buf.signature_help = with_default_opts(vim.lsp.buf.signature_help, floating_opts)

buf.hover = with_default_opts(vim.lsp.buf.hover, floating_opts)

local code_action_backup = vim.lsp.buf.code_action
---@param opts? vim.lsp.buf.code_action.Opts
function buf.code_action(opts)
    local ok, actions_preview = pcall(require, 'actions-preview')
    if ok then
        actions_preview.code_actions(opts)
    else
        code_action_backup(opts)
    end
end

buf.outgoing_calls = with_default_opts(vim.lsp.buf.outgoing_calls)
buf.incoming_calls = with_default_opts(vim.lsp.buf.incoming_calls)

buf.format = with_default_opts(vim.lsp.buf.format)

do
    -- stylua: ignore
    local methods = {
        references       = 'lsp_references',
        implementation   = 'lsp_implementations',
        definition       = 'lsp_definitions',
        type_definition  = 'lsp_type_definitions',
        declaration      = 'lsp_declarations',
        document_symbol  = 'lsp_symbols',
        workspace_symbol = 'lsp_workspace_symbols',
    }
    for method, source in pairs(methods) do
        buf[method] = function()
            require('snacks.picker').pick(source)
        end
    end
end

local M = {
    _backup = {},
}

function M.overwrite()
    for k, v in pairs(buf) do
        M._backup[k] = vim.lsp.buf[k]
        vim.lsp.buf[k] = v
    end
end

function M.restore()
    for k, v in pairs(M._backup) do
        vim.lsp.buf[k] = v
    end
end

return M
