local vim = vim
local api = vim.api

local a = require('dotvim.util.async')
local handlers = require('dotvim.config.lsp.handlers')
local my_lsp = require('dotvim.config.lsp.my')

local LspMethods = vim.lsp.protocol.Methods

local group_id = api.nvim_create_augroup('dotvim_lsp_init_on_attach', { clear = true })

local function set_lsp_keymaps(_, bufnr)
    local set_keymap = vim.keymap.set

    -- stylua: ignore
    local keymaps = {
        K   = { my_lsp.hover, 'show documentation' },
        gi  = { my_lsp.implementation, 'goto implementation' },
        gk  = { my_lsp.signature_help, 'show signature help' },
        gd  = { my_lsp.definition, 'goto definition' },
        gtd = { my_lsp.type_definition, 'goto type definition' },
        grr = { my_lsp.references, 'show references' },
        grn = { my_lsp.rename, 'rename' },
        gds = { my_lsp.document_symbol, 'show document symbols' },
        gws = { my_lsp.workspace_symbol, 'show workspace symbols' },
        gca = { my_lsp.code_action, 'code action' },
        go  = { my_lsp.outgoing_calls, 'show outgoing calls' },
        gcl = { my_lsp.codelens, 'find and run codelens' },
    }
    for key, action in pairs(keymaps) do
        set_keymap('n', key, action[1], {
            noremap = false,
            silent = true,
            buffer = bufnr,
            desc = '[Lsp] ' .. action[2],
        })
    end

    local show_menu = a.wrap(function()
        local choice = a.ui
            .select(vim.tbl_values(keymaps), {
                prompt = 'Lsp actions:',
                format_item = function(item)
                    -- uppercase the first letter
                    local display = item[2]:gsub('^%l', string.upper)
                    return display
                end,
            })
            .await()
        if choice then
            choice[1]()
        end
    end)

    set_keymap('n', '<space><space>', show_menu, {
        noremap = false,
        silent = true,
        buffer = bufnr,
        desc = '[Lsp] show menu',
    })
end

local function set_lsp_autocmd(client, bufnr)
    if client.supports_method(LspMethods.textDocument_documentHighlight) and client.name ~= 'rust_analyzer' then
        api.nvim_create_autocmd({ 'CursorHold' }, {
            group = group_id,
            buffer = bufnr,
            desc = '[Lsp] document highlight',
            callback = function()
                my_lsp.document_highlight()
            end,
        })
        api.nvim_create_autocmd({ 'CursorMoved' }, {
            group = group_id,
            buffer = bufnr,
            desc = '[Lsp] document highlight clear',
            callback = function()
                my_lsp.clear_references()
            end,
        })
    end

    if client.supports_method(LspMethods.textDocument_codeLens) then
        api.nvim_create_autocmd({ 'BufEnter', 'InsertLeave', 'BufWritePost', 'CursorHold' }, {
            group = group_id,
            buffer = bufnr,
            desc = '[lsp] codelens refresh',
            callback = function()
                vim.lsp.codelens.refresh({ bufnr = bufnr })
            end,
        })
        vim.schedule(function()
            vim.lsp.codelens.refresh({ bufnr = bufnr })
        end)
    end
end

local on_attach = function(client, bufnr)
    set_lsp_autocmd(client, bufnr)
    set_lsp_keymaps(client, bufnr)

    if client.supports_method(LspMethods.textDocument_inlayHint) then
        vim.schedule(function()
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        end)
    end

    if vim.bo[bufnr].filetype == 'helm' and client.name == 'gopls' then
        vim.defer_fn(function()
            vim.lsp.semantic_tokens.stop(bufnr, client.id)
        end, 100)
    end
end

local function default_capabilities()
    local capabilities = vim.lsp.protocol.make_client_capabilities()

    local cmp_lsp = vim.F.npcall(require, 'cmp_nvim_lsp')
    if cmp_lsp then
        capabilities = cmp_lsp.default_capabilities()
    end
    capabilities.textDocument.foldingRange = {
        dynamicRegistration = false,
        lineFoldingOnly = true,
    }
    return capabilities
end

return {
    on_attach = on_attach,
    capabilities = default_capabilities(),
    -- stylua: ignore
    handlers = {
        [LspMethods.workspace_symbol]            = handlers.symbol_handler,
        [LspMethods.textDocument_documentSymbol] = handlers.symbol_handler,
        [LspMethods.callHierarchy_outgoingCalls] = handlers.outgoing_calls,
    },
}
