---@alias LspClient vim.lsp.Client
---@alias OnAttachFunc fun(client: LspClient, bufnr: number):boolean?

local function make_capabilities()
    if vim.g.dotvim_lsp_capabilities then
        return vim.g.dotvim_lsp_capabilities()
    end
    return require('dotvim.config.lsp.capabilities')
end

local M = {}

function M.setup()
    require('dotvim.config.lsp.buf').overwrite()
    require('dotvim.config.lsp.utils').setup()
    require('dotvim.config.lsp.keymaps').setup()
    require('dotvim.config.lsp.autocmds').setup()

    local default_config = {
        capabilities = make_capabilities(),
    }
    vim.lsp.config('*', default_config)

    vim.lsp.enable('copilot-ls')
end

return M
