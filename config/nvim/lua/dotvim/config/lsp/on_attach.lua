local a = require('dotvim.util.async')
local my_lsp = require('dotvim.config.lsp.my')

local LspMethods = vim.lsp.protocol.Methods

---@alias Client vim.lsp.Client
---@alias OnAttachFunc fun(client: Client, bufnr: number)

---@param client Client
---@param bufnr number
local function set_keymaps(client, bufnr)
    local set_keymap = vim.keymap.set

    -- stylua: ignore
    local keymaps = {
        K   = { handler = my_lsp.hover,              desc = 'show documentation',     method = nil                                    },
        gi  = { handler = my_lsp.implementation,     desc = 'goto implementation',    method = LspMethods.textDocument_implementation },
        gk  = { handler = my_lsp.signature_help,     desc = 'show signature help',    method = LspMethods.textDocument_signatureHelp  },
        gd  = { handler = my_lsp.definition,         desc = 'goto definition',        method = LspMethods.textDocument_definition     },
        gpd = { handler = my_lsp.preview_definition, desc = 'preview definition',     method = LspMethods.textDocument_definition     },
        gtd = { handler = my_lsp.type_definition,    desc = 'goto type definition',   method = LspMethods.textDocument_typeDefinition },
        grr = { handler = my_lsp.references,         desc = 'show references',        method = LspMethods.textDocument_references     },
        grn = { handler = my_lsp.rename,             desc = 'rename',                 method = LspMethods.textDocument_rename         },
        gds = { handler = my_lsp.document_symbol,    desc = 'show document symbols',  method = LspMethods.textDocument_documentSymbol },
        gws = { handler = my_lsp.workspace_symbol,   desc = 'show workspace symbols', method = LspMethods.workspace_symbol            },
        gca = { handler = my_lsp.code_action,        desc = 'code action',            method = LspMethods.textDocument_codeAction     },
        goc = { handler = my_lsp.outgoing_calls,     desc = 'show outgoing calls',    method = LspMethods.callHierarchy_outgoingCalls },
        gic = { handler = my_lsp.incoming_calls,     desc = 'show incoming calls',    method = LspMethods.callHierarchy_incomingCalls },
        gcl = { handler = my_lsp.codelens,           desc = 'find and run codelens',  method = nil                                    },
    }
    for key, action in pairs(keymaps) do
        if not action.method or client:supports_method(action.method) then
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

local ctrlv = vim.api.nvim_replace_termcodes('<C-v>', true, true, true)

---@param client Client
---@param bufnr number
local function smart_inlayhint(client, bufnr)
    if not client:supports_method(LspMethods.textDocument_inlayHint) then
        return
    end

    vim.schedule(function()
        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        vim.b[bufnr].lsp_inlay_hint_enabled = true
    end)

    vim.b[bufnr].lsp_inlay_hint_autocmd_id = vim.b[bufnr].lsp_inlay_hint_autocmd_id
        or vim.api.nvim_create_autocmd({ 'InsertEnter', 'InsertLeave', 'ModeChanged' }, {
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

---@param client Client
---@param bufnr number
local function codelens_auto_refresh(client, bufnr)
    if not client:supports_method(LspMethods.textDocument_codeLens) then
        return
    end
    vim.b[bufnr].lsp_codelens_autocmd_id = vim.b[bufnr].lsp_codelens_autocmd_id
        or vim.api.nvim_create_autocmd({ 'BufEnter', 'InsertLeave', 'BufWritePost', 'CursorHold' }, {
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

---@param client Client
---@param bufnr number
local function auto_document_highlight(client, bufnr)
    if not client:supports_method(LspMethods.textDocument_documentHighlight) or client.name == 'rust_analyzer' then
        return
    end
    vim.b[bufnr].lsp_document_highlight_autocmd_id = vim.b[bufnr].lsp_document_highlight_autocmd_id
        or vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorMoved' }, {
            buffer = bufnr,
            desc = '[Lsp] document highlight',
            callback = function(args)
                if args.event == 'CursorHold' then
                    my_lsp.document_highlight()
                elseif args.event == 'CursorMoved' then
                    my_lsp.clear_references()
                end
            end,
        })
end

---@param client Client
---@param bufnr number
local function disable_semantic_token_for_helm(client, bufnr)
    if vim.bo[bufnr].filetype == 'helm' and client.name == 'gopls' then
        vim.defer_fn(function()
            vim.lsp.semantic_tokens.stop(bufnr, client.id)
        end, 100)
    end
end

---@type OnAttachFunc[]
local on_attach_funcs = {
    set_keymaps,
    auto_document_highlight,
    smart_inlayhint,
    codelens_auto_refresh,
    disable_semantic_token_for_helm,
}

---@param client Client
---@param bufnr number
local on_attach = function(client, bufnr)
    vim.iter(on_attach_funcs):each(function(fn)
        return fn(client, bufnr)
    end)
end

return on_attach
