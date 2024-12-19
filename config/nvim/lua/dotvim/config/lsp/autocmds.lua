---@diagnostic disable: unused-local
local my_lsp = require('dotvim.config.lsp.my')

local LspMethods = vim.lsp.protocol.Methods

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
    if client.name == 'rust_analyzer' then
        -- leave it to rustaceanvim
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
    if vim.bo[bufnr].filetype == 'helm' then
        vim.defer_fn(function()
            vim.lsp.semantic_tokens.stop(bufnr, client.id)
        end, 100)
    end
end

local autocmds = {
    {
        smart_inlayhint,
        method = LspMethods.textDocument_inlayHint,
        desc = 'toggle inlay hint',
    },
    {
        codelens_auto_refresh,
        method = LspMethods.textDocument_codeLens,
        desc = 'auto refresh codelens',
    },
    {
        auto_document_highlight,
        method = LspMethods.textDocument_documentHighlight,
        desc = 'auto document highlight',
    },
    {
        auto_format_on_save,
        method = LspMethods.textDocument_formatting,
        desc = 'format on save',
    },
    {
        disable_semantic_token_for_helm,
        name = 'gopls',
        desc = 'disable semantic token for helm',
    },
}

local M = {}

function M.setup()
    local lsputils = require('dotvim.config.lsp.utils')
    for _, autocmd in ipairs(autocmds) do
        if autocmd.method then
            lsputils.on_supports_method(autocmd.method, autocmd[1], { name = autocmd.name, desc = autocmd.desc })
        else
            lsputils.on_attach(autocmd[1], { name = autocmd.name, desc = autocmd.desc })
        end
    end
end

return M
