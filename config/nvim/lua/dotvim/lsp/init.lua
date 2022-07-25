local vim = vim
local api = vim.api

local handlers = require('dotvim.lsp.handlers')

local mason_lspcfg = vim.F.npcall(require, 'mason-lspconfig')
if not mason_lspcfg then
    vim.notify_once('mason not installed', 'ERROR')
    return
end
local lspconfig = require('lspconfig')

local nlspsettings = vim.F.npcall(require, 'nlspsettings')
if nlspsettings then
    nlspsettings.setup({
        config_home = vim.fn.stdpath('config') .. '/nlsp-settings',
        local_settings_dir = '.nlsp-settings',
        local_settings_root_markers = { '.git' },
        append_default_schemas = true,
        loader = 'json',
    })
end

local group_id = api.nvim_create_augroup('dotvim_lsp_init_on_attach', { clear = true })

local function set_lsp_keymaps(_client, bufnr)
    local key_opts = { noremap = false, silent = true, buffer = bufnr }
    local set_keymap = vim.keymap.set
    -- stylua: ignore
    local keymaps = {
        gd  = vim.lsp.buf.definition,
        K   = vim.lsp.buf.hover,
        gi  = vim.lsp.buf.implementation,
        gk  = vim.lsp.buf.signature_help,
        gtd = vim.lsp.buf.type_definition,
        gR  = vim.lsp.buf.references,
        grr = vim.lsp.buf.rename,
        gds = vim.lsp.buf.document_symbol,
        gws = vim.lsp.buf.workspace_symbol,
        gca = vim.lsp.buf.code_action,
        go  = vim.lsp.buf.outgoing_calls,
    }
    for key, action in pairs(keymaps) do
        set_keymap('n', key, action, key_opts)
    end
end

local function set_lsp_autocmd(client, bufnr)
    if client.supports_method('textDocument/formating') then
        api.nvim_create_autocmd({ 'BufWritePre' }, {
            group = group_id,
            buffer = bufnr,
            desc = '[lsp] auto format',
            callback = function()
                if not vim.g.lsp_disable_auto_format then
                    vim.lsp.buf.formatting_sync()
                end
            end,
        })
    end

    if client.supports_method('textDocument/documentHighlight') and client.name ~= 'rust_analyzer' then
        api.nvim_create_autocmd({ 'CursorHold' }, {
            group = group_id,
            buffer = bufnr,
            callback = function()
                vim.lsp.buf.document_highlight()
            end,
        })
        api.nvim_create_autocmd({ 'CursorMoved' }, {
            group = group_id,
            buffer = bufnr,
            callback = function()
                vim.lsp.buf.clear_references()
            end,
        })
    end
end

local on_attach = function(client, bufnr)
    set_lsp_autocmd(client, bufnr)
    set_lsp_keymaps(client, bufnr)
end

local default_capabilities = vim.lsp.protocol.make_client_capabilities()

local cmp_lsp = vim.F.npcall(require, 'cmp_nvim_lsp')
if cmp_lsp then
    default_capabilities = cmp_lsp.update_capabilities(default_capabilities)
end

-- stylua: ignore
local default_config = {
    on_attach = on_attach,
    capabilities = default_capabilities,
    handlers = {
        ['textDocument/hover']          = handlers.hover,
        ['workspace/symbol']            = handlers.symbol_handler,
        ['textDocument/references']     = handlers.references,
        ['textDocument/documentSymbol'] = handlers.symbol_handler,
        ['textDocument/definition']     = handlers.gen_location_handler('Definition'),
        ['textDocument/typeDefinition'] = handlers.gen_location_handler('TypeDefinition'),
        ['textDocument/implementation'] = handlers.gen_location_handler('Implementation'),
        ['callHierarchy/outgoingCalls'] = handlers.outgoing_calls,
    },
}

local function get_runtime_path()
    local runtime_path = vim.split(package.path, ';')
    table.insert(runtime_path, 'lua/?.lua')
    table.insert(runtime_path, 'lua/?/init.lua')
    table.insert(runtime_path, vim.env.VIM .. '/sysinit.lua')
    return runtime_path
end

local langs = {
    gopls = {
        filetypes = { 'go', 'gomod', 'gotmpl', 'helm' },
        settings = {
            gopls = {
                usePlaceholders = false,
                gofumpt = true,
                templateExtensions = { 'tpl', 'yaml' },
            },
        },
    },
    sumneko_lua = {
        settings = {
            -- https://github.com/sumneko/vscode-lua/blob/master/setting/schema.json
            Lua = {
                diagnostics = {
                    enable = true,
                    globals = {
                        'vim',
                        'pprint',
                    },
                    disable = {
                        'unused-vararg',
                        'unused-local',
                        'redefined-local',
                    },
                },
                runtime = {
                    version = 'LuaJIT',
                    path = get_runtime_path(),
                },
                workspace = {
                    library = vim.api.nvim_get_runtime_file('', true),
                    ignoreDir = {
                        '.cache',
                    },
                },
            },
        },
    },
}

mason_lspcfg.setup_handlers({
    function(server_name)
        local cfg = default_config
        if langs[server_name] then
            cfg = vim.tbl_deep_extend('force', cfg, langs[server_name])
        end
        if server_name == 'rust_analyzer' then
            require('dotvim.lsp.rust').setup(cfg)
        else
            lspconfig[server_name].setup(cfg)
        end
    end,
})
