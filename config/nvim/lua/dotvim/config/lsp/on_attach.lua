local a = require('dotvim.util.async')
local my_lsp = require('dotvim.config.lsp.my')

local LspMethods = vim.lsp.protocol.Methods

---@alias LspClient vim.lsp.Client
---@alias OnAttachFunc fun(client: LspClient, bufnr: number)

---@param client LspClient
---@param bufnr number
local function set_keymaps(client, bufnr)
    local set_keymap = vim.keymap.set

    -- stylua: ignore
    local keymaps = {
        K   = { 'hover',            desc = 'show documentation',     method = nil                                    },
        gi  = { 'implementation',   desc = 'goto implementation',    method = LspMethods.textDocument_implementation },
        gk  = { 'signature_help',   desc = 'show signature help',    method = LspMethods.textDocument_signatureHelp  },
        gd  = { 'definition',       desc = 'goto definition',        method = LspMethods.textDocument_definition     },
        gtd = { 'type_definition',  desc = 'goto type definition',   method = LspMethods.textDocument_typeDefinition },
        grr = { 'references',       desc = 'show references',        method = LspMethods.textDocument_references     },
        grn = { 'rename',           desc = 'rename',                 method = LspMethods.textDocument_rename         },
        gds = { 'document_symbol',  desc = 'show document symbols',  method = LspMethods.textDocument_documentSymbol },
        gws = { 'workspace_symbol', desc = 'show workspace symbols', method = LspMethods.workspace_symbol            },
        gca = { 'code_action',      desc = 'code action',            method = LspMethods.textDocument_codeAction     },
        goc = { 'outgoing_calls',   desc = 'show outgoing calls',    method = LspMethods.callHierarchy_outgoingCalls },
        gic = { 'incoming_calls',   desc = 'show incoming calls',    method = LspMethods.callHierarchy_incomingCalls },
        gcl = { my_lsp.codelens,    desc = 'find and run codelens',  method = nil                                    },
    }
    local function make_action(rhs)
        return function(...)
            if type(rhs) == 'function' then
                rhs(...)
            else
                vim.lsp.buf[rhs](...)
            end
        end
    end

    for key, rhs in pairs(keymaps) do
        if not rhs.method or client:supports_method(rhs.method) then
            set_keymap('n', key, make_action(rhs[1]), {
                noremap = false,
                silent = true,
                buffer = bufnr,
                desc = '[Lsp] ' .. rhs.desc,
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
        make_action(choice[1])()
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

---@param client LspClient
---@param bufnr number
local function smart_inlayhint(client, bufnr)
    if not client:supports_method(LspMethods.textDocument_inlayHint) then
        return
    end

    vim.schedule(function()
        vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
        vim.b[bufnr].lsp_inlay_hint_enabled = true
    end)

    local lsp_autocmds = vim.b[bufnr].lsp_autocmds or {}
    lsp_autocmds.inlay_hint = lsp_autocmds.inlay_hint
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

                    ---@diagnostic disable-next-line: undefined-field
                    if event.new_mode == ctrlv then
                        disable_inlayhint_temporary(args.buf)
                    ---@diagnostic disable-next-line: undefined-field
                    elseif event.old_mode == ctrlv then
                        restore_inlayhint(args.buf)
                    end
                end
            end,
        })
    vim.b[bufnr].lsp_autocmds = lsp_autocmds
end

---@param client LspClient
---@param bufnr number
local function codelens_auto_refresh(client, bufnr)
    if not client:supports_method(LspMethods.textDocument_codeLens) then
        return
    end
    local lsp_autocmds = vim.b[bufnr].lsp_autocmds or {}
    lsp_autocmds.codelens = lsp_autocmds.codelens
        or vim.api.nvim_create_autocmd({ 'BufEnter', 'InsertLeave', 'BufWritePost', 'CursorHold' }, {
            buffer = bufnr,
            desc = '[Lsp] codelens refresh',
            callback = function()
                vim.lsp.codelens.refresh({ bufnr = bufnr })
            end,
        })
    vim.b[bufnr].lsp_autocmds = lsp_autocmds

    vim.schedule(function()
        vim.lsp.codelens.refresh({ bufnr = bufnr })
    end)
end

---@param client LspClient
---@param bufnr number
local function auto_document_highlight(client, bufnr)
    if not client:supports_method(LspMethods.textDocument_documentHighlight) or client.name == 'rust_analyzer' then
        return
    end
    local lsp_autocmds = vim.b[bufnr].lsp_autocmds or {}
    lsp_autocmds.document_highlight = lsp_autocmds.document_highlight
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
    vim.b[bufnr].lsp_autocmds = lsp_autocmds
end

---@param client LspClient
---@param bufnr number
local function auto_format_on_save(client, bufnr)
    if not client:supports_method(LspMethods.textDocument_formatting) then
        return
    end
    if client.name ~= 'null-ls' and vim.b[bufnr].lsp_disable_auto_format then
        return
    end

    local lsp_autocmds = vim.b[bufnr].lsp_autocmds or {}
    lsp_autocmds.format = lsp_autocmds.format
        or vim.api.nvim_create_autocmd('BufWritePre', {
            buffer = bufnr,
            desc = '[Lsp] format on save',
            callback = function(args)
                local bufnr = args.buf
                ---@param client LspClient client passed here supports textDocument_formatting
                local filter = function(client)
                    if client.name == 'null-ls' then
                        return true
                    end
                    if vim.b[bufnr].lsp_disable_auto_format then
                        return false
                    end
                    return true
                end
                my_lsp.format({
                    bufnr = bufnr,
                    async = false,
                    filter = filter,
                })
            end,
        })
    vim.b[bufnr].lsp_autocmds = lsp_autocmds
end

---@param client LspClient
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
    auto_format_on_save,
    smart_inlayhint,
    codelens_auto_refresh,
    disable_semantic_token_for_helm,
}

local M = {}

---@param client LspClient
---@param bufnr number
local function on_attach(client, bufnr)
    vim.iter(on_attach_funcs):each(function(fn)
        return fn(client, bufnr)
    end)
end

function M.setup()
    local group_id = vim.api.nvim_create_augroup('dotvim_lsp_on_attach', { clear = true })
    vim.api.nvim_create_autocmd('LspAttach', {
        group = group_id,
        callback = function(args)
            local client = vim.lsp.get_client_by_id(args.data.client_id)
            assert(client, 'client not found')
            on_attach(client, args.buf)
        end,
    })
end

setmetatable(M, {
    __call = function(_, client, bufnr)
        on_attach(client, bufnr)
    end,
})

return M
