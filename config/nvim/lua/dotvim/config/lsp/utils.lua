local handlers = require('dotvim.config.lsp.handlers')

local on_attach = require('dotvim.config.lsp.on_attach')

local LspMethods = vim.lsp.protocol.Methods

local function default_capabilities()
    local capabilities = vim.lsp.protocol.make_client_capabilities()

    local cmp_lsp = vim.F.npcall(require, 'cmp_nvim_lsp')
    if cmp_lsp then
        capabilities = vim.tbl_deep_extend('force', capabilities, cmp_lsp.default_capabilities())
    end
    return capabilities
end

return {
    on_attach = on_attach,
    capabilities = default_capabilities(),
    -- stylua: ignore
    handlers = {
        [LspMethods.callHierarchy_outgoingCalls] = handlers.outgoing_calls,
    },
}
