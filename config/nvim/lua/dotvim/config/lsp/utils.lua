local vim = vim
local api = vim.api

local a = require('dotvim.util.async')
local handlers = require('dotvim.config.lsp.handlers')

local LspMethods = vim.lsp.protocol.Methods

--- copy from https://github.com/williamboman/nvim-config/blob/main/lua/wb/lsp/on-attach.lua
local function find_and_run_codelens()
    local bufnr = vim.api.nvim_get_current_buf()
    local row, col = unpack(vim.api.nvim_win_get_cursor(0))
    local lenses = vim.lsp.codelens.get(bufnr)

    lenses = vim.tbl_filter(function(lense)
        return lense.range.start.line < row
    end, lenses)

    if #lenses == 0 then
        vim.notify('Could not find codelens to run.', vim.log.levels.WARN)
        return
    end

    table.sort(lenses, function(a, b)
        return a.range.start.line > b.range.start.line
    end)

    vim.api.nvim_win_set_cursor(0, { lenses[1].range.start.line + 1, lenses[1].range.start.character })
    vim.lsp.codelens.run()
    vim.api.nvim_win_set_cursor(0, { row, col }) -- restore cursor, TODO: also restore position
end

local group_id = api.nvim_create_augroup('dotvim_lsp_init_on_attach', { clear = true })

local function my_show_documentation()
    local clients = vim.lsp.get_clients({ name = 'taplo' })
    if clients and vim.fn.expand('%:t') == 'Cargo.toml' and require('crates').popup_available() then
        require('crates').show_popup()
        return
    end
    local ok, ufo = pcall(require, 'ufo')
    if ok then
        local winid = ufo.peekFoldedLinesUnderCursor()
        if winid then
            return
        end
    end

    vim.lsp.buf.hover()
end

local function code_action(...)
    local ok, actions_preview = pcall(require, 'actions-preview')
    if ok then
        actions_preview.code_actions(...)
    else
        vim.lsp.buf.code_action(...)
    end
end

local function set_lsp_keymaps(_, bufnr)
    local set_keymap = vim.keymap.set

    -- stylua: ignore
    local keymaps = {
        gd  = { vim.lsp.buf.definition, 'goto definition' },
        K   = { my_show_documentation, 'show documentation' },
        gi  = { vim.lsp.buf.implementation, 'goto implementation' },
        gk  = { vim.lsp.buf.signature_help, 'show signature help' },
        gtd = { vim.lsp.buf.type_definition, 'goto type definition' },
        gR  = { vim.lsp.buf.references, 'show references' },
        grr = { vim.lsp.buf.rename, 'rename' },
        gds = { vim.lsp.buf.document_symbol, 'show document symbols' },
        gws = { vim.lsp.buf.workspace_symbol, 'show workspace symbols' },
        gca = { code_action, 'code action' },
        go  = { vim.lsp.buf.outgoing_calls, 'show outgoing calls' },
        gcl = { find_and_run_codelens, 'find and run codelens' },
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
                vim.lsp.buf.document_highlight()
            end,
        })
        api.nvim_create_autocmd({ 'CursorMoved' }, {
            group = group_id,
            buffer = bufnr,
            desc = '[Lsp] document highlight clear',
            callback = function()
                vim.lsp.buf.clear_references()
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
        capabilities = cmp_lsp.default_capabilities(capabilities)
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
        [LspMethods.textDocument_references]     = handlers.references,
        [LspMethods.textDocument_documentSymbol] = handlers.symbol_handler,
        [LspMethods.textDocument_definition]     = handlers.gen_location_handler('Definition'),
        [LspMethods.textDocument_typeDefinition] = handlers.gen_location_handler('TypeDefinition'),
        [LspMethods.textDocument_implementation] = handlers.gen_location_handler('Implementation'),
        [LspMethods.callHierarchy_outgoingCalls] = handlers.outgoing_calls,
    },
}
