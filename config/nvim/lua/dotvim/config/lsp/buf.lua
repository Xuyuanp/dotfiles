local buf = {}

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

-- stylua: ignore
local picker_methods = {
    references       = 'lsp_references',
    implementation   = 'lsp_implementations',
    definition       = 'lsp_definitions',
    type_definition  = 'lsp_type_definitions',
    declaration      = 'lsp_declarations',
    document_symbol  = 'lsp_symbols',
    workspace_symbol = 'lsp_workspace_symbols',
}
for method, source in pairs(picker_methods) do
    buf[method] = function()
        local ok, picker = pcall(require, 'snacks.picker')
        if ok then
            picker.pick(source)
        else
            vim.lsp.buf[method]()
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
