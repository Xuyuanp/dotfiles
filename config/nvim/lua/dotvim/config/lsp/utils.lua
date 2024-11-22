local vim = vim
local api = vim.api

local a = require('dotvim.util.async')
local handlers = require('dotvim.config.lsp.handlers')
local my_lsp = require('dotvim.config.lsp.my')

local LspMethods = vim.lsp.protocol.Methods

local group_id = api.nvim_create_augroup('dotvim_lsp_init_on_attach', { clear = true })

local function set_lsp_keymaps(client, bufnr)
    local set_keymap = vim.keymap.set

    -- stylua: ignore
    local keymaps = {
        K   = { handler = my_lsp.hover,            desc = 'show documentation',     method = nil},
        gi  = { handler = my_lsp.implementation,   desc = 'goto implementation',    method = LspMethods.textDocument_implementation},
        gk  = { handler = my_lsp.signature_help,   desc = 'show signature help',    method = LspMethods.textDocument_signatureHelp},
        gd  = { handler = my_lsp.definition,       desc = 'goto definition',        method = LspMethods.textDocument_definition},
        gtd = { handler = my_lsp.type_definition,  desc = 'goto type definition',   method = LspMethods.textDocument_typeDefinition},
        grr = { handler = my_lsp.references,       desc = 'show references',        method = LspMethods.textDocument_references},
        grn = { handler = my_lsp.rename,           desc = 'rename',                 method = LspMethods.textDocument_rename},
        gds = { handler = my_lsp.document_symbol,  desc = 'show document symbols',  method = LspMethods.textDocument_documentSymbol},
        gws = { handler = my_lsp.workspace_symbol, desc = 'show workspace symbols', method = LspMethods.workspace_symbol},
        gca = { handler = my_lsp.code_action,      desc = 'code action',            method = LspMethods.textDocument_codeAction},
        go  = { handler = my_lsp.outgoing_calls,   desc = 'show outgoing calls',    method = LspMethods.callHierarchy_outgoingCalls},
        gcl = { handler = my_lsp.codelens,         desc = 'find and run codelens',  method = nil},
    }
    for key, action in pairs(keymaps) do
        if action.method and not client.supports_method(action.method) then
            keymaps[key] = nil
        else
            set_keymap('n', key, action.handler, {
                noremap = false,
                silent = true,
                buffer = bufnr,
                desc = '[Lsp] ' .. action.desc,
            })
        end
    end

    local show_menu = a.wrap(function()
        local choices = vim.tbl_values(keymaps)
        local choice = a.ui
            .select(choices, {
                prompt = 'Lsp actions:',
                format_item = function(item)
                    -- uppercase the first letter
                    local display = item.desc:gsub('^%l', string.upper)
                    return display
                end,
            })
            .await()
        if not choice then
            return
        end
        choice.handler()
    end)

    set_keymap('n', '<space><space>', show_menu, {
        noremap = false,
        silent = true,
        buffer = bufnr,
        desc = '[Lsp] show menu',
    })
end

local function disable_inlayhint_temporary(bufnr)
    local enabled = vim.lsp.inlay_hint.is_enabled({ bufnr = bufnr })
    vim.b[bufnr].lsp_inlay_hint_enabled = enabled
    if not enabled then
        return
    end
    vim.lsp.inlay_hint.enable(false, { bufnr = bufnr })
end

local function restore_inlayhint(bufnr)
    if not vim.b[bufnr].lsp_inlay_hint_enabled then
        return
    end
    vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
end

local function smart_inlayhint(bufnr)
    local ctrlv = vim.api.nvim_replace_termcodes('<C-v>', true, true, true)
    vim.api.nvim_create_autocmd({ 'InsertEnter', 'InsertLeave', 'ModeChanged' }, {
        group = group_id,
        buffer = bufnr,
        desc = '[Lsp] inlay hint toggle',
        callback = function(args)
            if args.event == 'InsertEnter' then
                disable_inlayhint_temporary(args.buf)
            elseif args.event == 'InsertLeave' then
                restore_inlayhint(args.buf)
            elseif args.event == 'ModeChanged' then
                local event = vim.v.event

                if event.new_mode == ctrlv then
                    disable_inlayhint_temporary(args.buf)
                elseif event.old_mode == ctrlv then
                    restore_inlayhint(args.buf)
                end
            end
        end,
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
            desc = '[Lsp] codelens refresh',
            callback = function()
                vim.lsp.codelens.refresh({ bufnr = bufnr })
            end,
        })
        vim.schedule(function()
            vim.lsp.codelens.refresh({ bufnr = bufnr })
        end)
    end

    if client.supports_method(LspMethods.textDocument_inlayHint) then
        vim.schedule(function()
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
            vim.b[bufnr].lsp_inlay_hint_enabled = true
        end)

        smart_inlayhint(bufnr)
    end
end

local on_attach = function(client, bufnr)
    set_lsp_autocmd(client, bufnr)
    set_lsp_keymaps(client, bufnr)

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
